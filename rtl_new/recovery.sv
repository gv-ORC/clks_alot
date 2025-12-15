/*
1. Recover Events
2. Send Events to the appropriate one (of two) `rate_recovery` modules
3. Forward Events and Rates to generation system
*/
module recovery (
    input                            common_p::clk_dom_s sys_dom_i,

    input                                                recovery_en_i,
    input                                                clear_state_i,

    // Used for differential and quad-state signals to decide which input is used to determine the primary clock edges
    // 0: io_clk_i.neg edges are forwarded, with io_clk_i.pos used for verification
    // 1: io_clk_i.pos edges are forwarded, with io_clk_i.neg used for verification
    // Use for single-ended signals to decide which input is used as the clock signal
    // 0: io_clk_i.neg used
    // 1: io_clk_i.pos used
    input                                                source_select_i,
    input                            clks_alot_p::mode_e recovery_mode_i,

    input                   clks_alot_p::recovery_pins_s io_clk_i,

// Bandpass
    input        [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_upper_bound_i,
    input        [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_lower_bound_i,
    output                                               bandpass_overshoot_o,
    output                                               bandpass_undershoot_o,

// Drift
    // If 1: Only allow drift in 1 direction
    // If 0: Allow drift in both directions
    input                                                drift_polarity_en_i,
    // If 1: Allow positive drift only
    // If 0: Allow negative drift only
    input                                                drift_polarity_i,
    input        [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_window_i,
    output                                               positive_drift_violation_o,
    output                                               negative_drift_violation_o,

// Halving - Forces the high rate to monitor both edges, not just one... allowing it to more accurately recover a clock from data.
    // Low rate output is disabled during this mode...
    input                                                clock_encoded_data_en_i,
    // When `clock_encoded_data_en_i` is 1:
    //  > If 1: When full-rate comes back odd, the high-rate has the extra cycle added
    //  > If 0: When full-rate comes back odd, the low-rate has the extra cycle added
    input                                                rounding_polarity_i,

// Priotization Configuration   
    input                          [COUNT_BIT_WIDTH-1:0] growth_rate_i,
    input                          [COUNT_BIT_WIDTH-1:0] decay_rate_i,
    // `saturation_limit_i` needs to be at least 1 growth rate below the max allowed by `clks_alot_p::PRIORITIZE_COUNTER_WIDTH`
    input                          [COUNT_BIT_WIDTH-1:0] saturation_limit_i,
    // `plateau_limit_i` needs to be at greater-than or equal-to `decay_rate_i`
    input                          [COUNT_BIT_WIDTH-1:0] plateau_limit_i,

// Output
    output                                               recovered_clk,
    output               clks_alot_p::recovered_events_s recovered_events_o,
    // Raises when both High and Low are locked-in ... for when you want to ensure you have a 50% clock duty cycle
    output                                               fully_locked_in_o,
    output                                               high_locked_in_o,
    output                                               high_rate_changed_o,
    output       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_rate_o,
    output                                               low_locked_in_o,
    output                                               low_rate_changed_o,
    output logic [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_rate_o
);

    clks_alot_p::recovered_events_s recovered_events;
    //TODO: May need to buffer these events
    event_recovery event_recovery (
        .sys_dom_i         (sys_dom_i),
        .recovery_en_i     (recovery_en_i),
        .source_select_i   (source_select_i),
        .recovery_mode_i   (recovery_mode_i),
        .io_clk_i          (io_clk_i),
        .primary_clk_o     (recovered_clk),
        .recovered_events_o(recovered_events)
    );

// High/Full Rate
    wire                                           recovered_high_rate;
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] halved_rate = {1'b0, recovered_high_rate[(clks_alot_p::RATE_COUNTER_WIDTH)-1:1]};
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rounded_rate = halved_rate + clks_alot_p::RATE_COUNTER_WIDTH'(recovered_high_rate[0]);
    assign                                         high_rate_o =( clock_encoded_data_en_i && rounding_polarity_i)
                                                               ? rounded_rate
                                                               : recovered_high_rate;

    rate_recovery high_rate_recovery (
        .sys_dom_i                 (sys_dom_i),
        .recovery_en_i             (recovery_en_i),
        .clear_state_i             (clear_state_i),
        .event_polarity_en_i       (~clock_encoded_data_en_i),
        .event_polarity_i          (1'b1),
        .io_events_i               (recovered_events),
        .bandpass_upper_bound_i    (bandpass_upper_bound_i),
        .bandpass_lower_bound_i    (bandpass_lower_bound_i),
        .bandpass_overshoot_o      (bandpass_overshoot_o),
        .bandpass_undershoot_o     (bandpass_undershoot_o),
        .drift_polarity_en_i       (drift_polarity_en_i),
        .drift_polarity_i          (drift_polarity_i),
        .drift_window_i            (drift_window_i),
        .positive_drift_violation_o(positive_drift_violation_o),
        .negative_drift_violation_o(negative_drift_violation_o),
        .clock_encoded_data_en_i   (clock_encoded_data_en_i),
        .growth_rate_i             (growth_rate_i),
        .decay_rate_i              (decay_rate_i),
        .saturation_limit_i        (saturation_limit_i),
        .plateau_limit_i           (plateau_limit_i),
        .io_events_o               (recovered_events_o),
        .locked_in_o               (high_locked_in_o),
        .speed_change_detected_o   (high_rate_changed_o),
        .rate_o                    (recovered_high_rate)
    );

// Low Rate
    wire low_rate_recovery_en = recovery_en && ~clock_encoded_data_en_i;
    wire recovered_low_locked_in;
    wire recovered_low_rate;

    assign fully_locked_in_o = (recoverd_low_locked_in || ~clock_encoded_data_en_i) && high_locked_in_o;
    assign low_locked_in_o = clock_encoded_data_en_i
                           ? high_locked_in_o
                           : recoverd_low_locked_in;

    wire   [1:0] low_rate_condition;
    assign       low_rate_condition[0] = clock_encoded_data_en_i && ~rounding_polarity_i;
    assign       low_rate_condition[1] = clock_encoded_data_en_i;
    always_comb begin : low_rate_mux
        case (low_rate_condition)
            2'b00  : low_rate_o = recovered_low_rate; // Normal Operation
            2'b01  : low_rate_o = recovered_low_rate; // Normal Operation
            2'b10  : low_rate_o = rounded_down_rate;  // Clock Encoded Data - Rouding Down
            2'b11  : low_rate_o = halved_rate;        // Clock Encoded Data - Rouding Down
            default: low_rate_o = clks_alot_p::RATE_COUNTER_WIDTH'(0);
        endcase
    end

    rate_recovery low_rate_recovery (
        .sys_dom_i                 (sys_dom_i),
        .recovery_en_i             (low_rate_recovery_en),
        .clear_state_i             (clear_state_i),
        .event_polarity_en_i       (1'b1),
        .event_polarity_i          (1'b0),
        .io_events_i               (recovered_events),
        .bandpass_upper_bound_i    (bandpass_upper_bound_i),
        .bandpass_lower_bound_i    (bandpass_lower_bound_i),
        .bandpass_overshoot_o      (bandpass_overshoot_o),
        .bandpass_undershoot_o     (bandpass_undershoot_o),
        .drift_polarity_en_i       (drift_polarity_en_i),
        .drift_polarity_i          (drift_polarity_i),
        .drift_window_i            (drift_window_i),
        .positive_drift_violation_o(positive_drift_violation_o),
        .negative_drift_violation_o(negative_drift_violation_o),
        .clock_encoded_data_en_i   (clock_encoded_data_en_i),
        .growth_rate_i             (growth_rate_i),
        .decay_rate_i              (decay_rate_i),
        .saturation_limit_i        (saturation_limit_i),
        .plateau_limit_i           (plateau_limit_i),
        .io_events_o               (), // Not Used: Only needed from 1 of these modules
        .locked_in_o               (recovered_low_locked_in),
        .speed_change_detected_o   (low_rate_changed_o),
        .rate_o                    (recovered_low_rate)
    );

endmodule : recovery
