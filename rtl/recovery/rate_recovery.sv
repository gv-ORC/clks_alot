module rate_recovery (
    input                           common_p::clk_dom_s sys_dom_i,

    input                                               recovery_en_i,
    input                                               clear_state_i,

// Events
    // If 1: Only allow events from a single edge
    // If 0: Accept events from both Rising and Falling edges
    input                                               event_polarity_en_i,
    // If 1: Only accept Rising Edges
    // If 0: Only accept Falling Edges
    input                                               event_polarity_i,
    input               clks_alot_p::recovered_events_s io_events_i,

// Bandpass
    input       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_upper_bound_i,
    input       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_lower_bound_i,
    output                                              bandpass_overshoot_o,
    output                                              bandpass_undershoot_o,

// Drift
    // If 1: Only allow drift in 1 direction
    // If 0: Allow drift in both directions
    input                                               drift_polarity_en_i,
    // If 1: Allow positive drift only
    // If 0: Allow negative drift only
    input                                               drift_polarity_i,
    input       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_window_i,
    output                                              positive_drift_violation_o,
    output                                              negative_drift_violation_o,

// Halving
    input                                               clock_encoded_data_en_i,

// Priotization Configuration   
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] growth_rate_i,
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] decay_rate_i,
    // `saturation_limit_i` needs to be at least 1 growth rate below the max allowed by `clks_alot_p::PRIORITIZE_COUNTER_WIDTH`
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] saturation_limit_i,
    // `plateau_limit_i` needs to be at greater-than or equal-to `decay_rate_i`
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] plateau_limit_i,

// Result
    output              clks_alot_p::recovered_events_s io_events_o, // Apply any required delay here.
    output                                              locked_in_o,
    output                                              speed_change_detected_o,
    output      [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rate_o
);

/*
Primary events reset counter and submit current counter value into a `binary_value_prioritizer`
Secondary events reset counter

Until the priorizer has locked-in... every bandpass approved event is treated as a primary.

// TODO: Have a system to manage multi-bit streaks -- I dont think this needs any extra work? Events will realign anyway... ?
*/


    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] null_seed = clks_alot_p::RATE_COUNTER_WIDTH'(0);
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] counter_growth_rate = clks_alot_p::RATE_COUNTER_WIDTH'(1);

    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] pending_rate;
    counter #(
        BIT_WIDTH(clks_alot_p::RATE_COUNTER_WIDTH)
    ) rate_counter (
        .sys_dom_i    (sys_dom_i),
        .counter_en_i (recovery_en_i),
        .init_en_i    (clear_state_i),
        .decay_en_i   (1'b1),
        .seed_i       (null_seed),
        .growth_rate_i(counter_growth_rate),
        .decay_rate_i (null_seed),
        .clear_en_i   (io_events_i.any_valid_edge),
        .count_o      (pending_rate)
    );

    wire primary_event;
    recovery_lockin_and_filtering recovery_lockin_and_filtering (
        .event_polarity_en_i       (event_polarity_en_i),
        .event_polarity_i          (event_polarity_i),
        .io_events_i               (io_events_i),
        .pending_rate_i            (pending_rate),
        .validated_rate_i          (rate_o),
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
        .rate_locked_in_i          (locked_in_o),
        .primary_event_o           (primary_event)
    );

    wire b_is_prioritized;
    binary_value_prioritizer #(
        VALUE_BIT_WIDTH(clks_alot_p::RATE_COUNTER_WIDTH),
        COUNT_BIT_WIDTH(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)
    ) rate_prioritizer (
        .sys_dom_i         (sys_dom_i),
        .clear_state_i     (clear_state_i),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_limit_i   (plateau_limit_i),
        .we_i              (primary_event),
        .data_i            (pending_rate),
        .locked_in_o       (locked_in_o),
        .b_is_prioritized_o(b_is_prioritized),
        .data_o            (rate_o)
    );

    wire speed_change_check_en = locked_in_o && recovery_en_i;
    monostable_full #(
        .BUFFERED(1'b1)
    ) speed_change_monostable (
        .clk_dom_s_i    (sys_dom_i),
        .monostable_en_i(speed_change_check_en),
        .sense_i        (b_is_prioritized),
        .prev_o         (), // Not Used
        .posedge_mono_o (), // Not Used
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o(speed_change_detected_o)
    );

    assign io_events_o = io_events_i; // Currently there is no delay on any logic - This may change when looking into the fmax

endmodule : rate_recovery
