module top (
    input                           common_p::clk_dom_s sys_dom_i,
    input                                               enable_i,
    input                                               recover_i,
    input                                               clear_state_i,

    input                                               init_i,
    // ToDo: This assumes a state of the clock... need a way to properly forward the phase to prevent edges from being flipped... this may auto-correct using existing math tho...
    input                                               starting_polarity_i,

    input       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_high_rate_i,
    input       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_low_rate_i,
    input       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_full_rate_i,

    input                                               source_select_i,
    input                           clks_alot_p::mode_e recovery_mode_i,

    input                  clks_alot_p::recovery_pins_s io_clk_i,

    output                                              high_rate_bandpass_overshoot_o,
    output                                              high_rate_bandpass_undershoot_o,
    output                                              low_rate_bandpass_overshoot_o,
    output                                              low_rate_bandpass_undershoot_o,

    output                                              high_rate_positive_drift_violation_o,
    output                                              high_rate_negative_drift_violation_o,
    output                                              low_rate_positive_drift_violation_o,
    output                                              low_rate_negative_drift_violation_o,
    output                                              excessive_drift_violation_o,

    output                                              expected_delta_mismatch_violation_o,
    output                                              preemptive_delta_mismatch_violation_o,

    output                   clks_alot_p::clock_state_s recovered_clk_state_o,

    output                   clks_alot_p::clock_state_s unpausable_expected_clk_state_o,
    output                   clks_alot_p::clock_state_s unpausable_preemptive_clk_state_o,

    input                                               pause_en_i,
    input                                               pause_polarity_i,
    output                   clks_alot_p::clock_state_s pausable_expected_clk_state_o,
    output                   clks_alot_p::clock_state_s pausable_preemptive_clk_state_o
);

// Recovery
    wire                                               recovery_en = enable_i && recover_i;

    // ToDo: Test variations of this
    wire       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_upper_bound = clks_alot_p::RATE_COUNTER_WIDTH'(10);
    wire       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_lower_bound = clks_alot_p::RATE_COUNTER_WIDTH'(4);

    // ToDo: Test variations of this
    wire                                               drift_polarity_en = 1'b0;
    wire                                               drift_polarity = 1'b0;
    wire       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_window = clks_alot_p::RATE_COUNTER_WIDTH'(1);

    // ToDo: Test variations of this
    wire                                               clock_encoded_data_en = 1'b0;
    wire                                               rounding_polarity = 1'b0;

    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_growth_rate = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(4);
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_decay_rate = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(1);
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_saturation_limit = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(32);
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_plateau_limit = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(16);
    // Throw an error if more than 1/10 of cycles are drifts
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_growth_rate = clks_alot_p::VIOLATION_COUNTER_WIDTH'(10);
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_decay_rate = clks_alot_p::VIOLATION_COUNTER_WIDTH'(1);
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_saturation_limit = clks_alot_p::VIOLATION_COUNTER_WIDTH'(20);
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_trigger_limit = clks_alot_p::VIOLATION_COUNTER_WIDTH'(11);

    wire                                               recovered_clk;
    clks_alot_p::recovered_events_s                    recovered_events;
    wire                                               fully_locked_in;
    wire                                               high_locked_in;
    wire                                               high_rate_changed;
    wire       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_rate;
    wire                                               low_locked_in;
    wire                                               low_rate_changed;
    wire       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_rate;
    wire       [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] full_rate;

    assign recovered_clk_state_o.clk = recovered_clk;
    assign recovered_clk_state_o.status.pause_active = 1'b0;
    assign recovered_clk_state_o.status.pause_duration = clks_alot_p::RATE_COUNTER_WIDTH'(0);
    assign recovered_clk_state_o.status.locked = fully_locked_in;
    assign recovered_clk_state_o.events = recovered_events;

    recovery recovery (
        .sys_dom_i                           (sys_dom_i),
        .recovery_en_i                       (recovery_en),
        .clear_state_i                       (clear_state_i),
        .source_select_i                     (source_select_i),
        .recovery_mode_i                     (recovery_mode_i),
        .io_clk_i                            (io_clk_i),
        .bandpass_upper_bound_i              (bandpass_upper_bound),
        .bandpass_lower_bound_i              (bandpass_lower_bound),
        .high_rate_bandpass_overshoot_o      (high_rate_bandpass_overshoot_o),
        .high_rate_bandpass_undershoot_o     (high_rate_bandpass_undershoot_o),
        .low_rate_bandpass_overshoot_o       (low_rate_bandpass_overshoot_o),
        .low_rate_bandpass_undershoot_o      (low_rate_bandpass_undershoot_o),
        .drift_polarity_en_i                 (drift_polarity_en),
        .drift_polarity_i                    (drift_polarity),
        .drift_window_i                      (drift_window),
        .high_rate_positive_drift_violation_o(high_rate_positive_drift_violation_o),
        .high_rate_negative_drift_violation_o(high_rate_negative_drift_violation_o),
        .low_rate_positive_drift_violation_o (low_rate_positive_drift_violation_o),
        .low_rate_negative_drift_violation_o (low_rate_negative_drift_violation_o),
        .excessive_drift_violation_o         (excessive_drift_violation_o),
        .clock_encoded_data_en_i             (clock_encoded_data_en),
        .rounding_polarity_i                 (rounding_polarity),
        .prioritization_growth_rate_i        (prioritization_growth_rate),
        .prioritization_decay_rate_i         (prioritization_decay_rate),
        .prioritization_saturation_limit_i   (prioritization_saturation_limit),
        .prioritization_plateau_limit_i      (prioritization_plateau_limit),
        .violation_growth_rate_i             (violation_growth_rate),
        .violation_decay_rate_i              (violation_decay_rate),
        .violation_saturation_limit_i        (violation_saturation_limit),
        .violation_trigger_limit_i           (violation_trigger_limit),
        .recovered_clk_o                     (recovered_clk),
        .recovered_events_o                  (recovered_events),
        .fully_locked_in_o                   (fully_locked_in),
        .high_locked_in_o                    (high_locked_in),
        .high_rate_changed_o                 (high_rate_changed),
        .high_rate_o                         (high_rate),
        .low_locked_in_o                     (low_locked_in),
        .low_rate_changed_o                  (low_rate_changed),
        .low_rate_o                          (low_rate),
        .full_rate_o                         (full_rate)
    );

// Generation
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rx_cycle_delay = clks_alot_p::RATE_COUNTER_WIDTH'(3);
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] tx_cycle_delay = clks_alot_p::RATE_COUNTER_WIDTH'(3);

    wire final_high_rate = generation_en
                         ? generation_high_rate_o
                         : high_rate;
    wire final_low_rate = generation_en
                         ? generation_low_rate_o
                         : low_rate;
    wire final_full_rate = generation_en
                         ? generation_full_rate_o
                         : full_rate;

    // Use the same as Recovery for now.
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] delta_prioritization_growth_rate = prioritization_growth_rate;
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] delta_prioritization_decay_rate = prioritization_decay_rate;
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] delta_prioritization_saturation_limit = prioritization_saturation_limit;
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] delta_prioritization_plateau_limit = prioritization_plateau_limit;

    generation generation (
        .sys_dom_i                              (sys_dom_i),
        .generation_en_i                        (enable_i),
        .init_i                                 (init_i),
        .starting_polarity_i                    (starting_polarity_i),
        .clear_state_i                          (clear_state_i),
        .rx_cycle_delay_i                       (rx_cycle_delay),
        .tx_cycle_delay_i                       (tx_cycle_delay),
        .recovered_events_i                     (recovered_events),
        .fully_locked_in_i                      (fully_locked_in),
        .high_rate_i                            (final_high_rate),
        .low_rate_i                             (final_low_rate),
        .full_rate_i                            (final_full_rate),
        .delta_prioritization_growth_rate_i     (delta_prioritization_growth_rate),
        .delta_prioritization_decay_rate_i      (delta_prioritization_decay_rate),
        .delta_prioritization_saturation_limit_i(delta_prioritization_saturation_limit),
        .delta_prioritization_plateau_limit_i   (delta_prioritization_plateau_limit),
        .expected_delta_mismatch_violation_o    (expected_delta_mismatch_violation_o),
        .preemptive_delta_mismatch_violation_o  (preemptive_delta_mismatch_violation_o),
        .unpausable_expected_clk_state_o        (unpausable_expected_clk_state_o),
        .unpausable_preemptive_clk_state_o      (unpausable_preemptive_clk_state_o),
        .pause_en_i                             (pause_en_i),
        .pause_polarity_i                       (pause_polarity_i),
        .pausable_expected_clk_state_o          (pausable_expected_clk_state_o),
        .pausable_preemptive_clk_state_o        (pausable_preemptive_clk_state_o)
    );

// Violation Control
    /*
    For violation control, have a system like CPU CSRs where you can choose which violations are serious, which are not, and have the option to mute them as needed.. like during boot.
    Have a mechanism that can be enabled that automatically mutes certain violations prior to lock-in... this can just be another layer of control

    Have 2 interrupt pins, 1 for Errors and 1 for Warnings... if any violation of the respective type goes high... keep it high until the violation status register is read from
    Pre-Locked Ignore, Error, Warning, Post-Locked Ignore
    */

endmodule : top
