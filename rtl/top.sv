module top (
    // input  common_p::clk_dom_s sys_dom_i, //! Use the init/config handshake



    output clks_alot_p::clock_status_s recover_status_o, // Recovery

    output clks_alot_p::generated_events_s actual_clks_o,    // Recovery
    output clks_alot_p::generated_events_s expected_clks_o,  // Generation
    output clks_alot_p::generated_events_s preemetive_clks_o // Generation
);

// Configuration

// Recovery
    recovery recovery (
        .sys_dom_i                           (sys_dom_i),
        .recovery_en_i                       (),
        .clear_state_i                       (),
        .source_select_i                     (),
        .recovery_mode_i                     (),
        .io_clk_i                            (),
        .bandpass_upper_bound_i              (),
        .bandpass_lower_bound_i              (),
        .high_rate_bandpass_overshoot_o      (),
        .high_rate_bandpass_undershoot_o     (),
        .low_rate_bandpass_overshoot_o       (),
        .low_rate_bandpass_undershoot_o      (),
        .drift_polarity_en_i                 (),
        .drift_polarity_i                    (),
        .drift_window_i                      (),
        .high_rate_positive_drift_violation_o(),
        .high_rate_negative_drift_violation_o(),
        .low_rate_positive_drift_violation_o (),
        .low_rate_negative_drift_violation_o (),
        .excessive_drift_violation_o         (),
        .clock_encoded_data_en_i             (),
        .rounding_polarity_i                 (),
        .prioritization_growth_rate_i        (),
        .prioritization_decay_rate_i         (),
        .prioritization_saturation_limit_i   (),
        .prioritization_plateau_limit_i      (),
        .violation_growth_rate_i             (),
        .violation_decay_rate_i              (),
        .violation_saturation_limit_i        (),
        .violation_trigger_limit_i           (),
        .recovered_clk                       (),
        .recovered_events_o                  (),
        .fully_locked_in_o                   (),
        .high_locked_in_o                    (),
        .high_rate_changed_o                 (),
        .high_rate_o                         (),
        .low_locked_in_o                     (),
        .low_rate_changed_o                  (),
        .low_rate_o                          ()
    );

// Generation
    generation generation (
        .sys_dom_i                              (),
        .generation_en_i                        (),
        .init_i                                 (),
        .starting_polarity_i                    (),
        .clear_state_i                          (),
        .recovered_events_i                     (),
        .fully_locked_in_i                      (),
        .high_rate_i                            (),
        .low_rate_i                             (),
        .full_rate_i                            (),
        .delta_prioritization_growth_rate_i     (),
        .delta_prioritization_decay_rate_i      (),
        .delta_prioritization_saturation_limit_i(),
        .delta_prioritization_plateau_limit_i   (),
        .expected_delta_mismatch_violation_o    (),
        .preemptive_delta_mismatch_violation_o  (),
        .unpausable_expected_clk_state_o        (),
        .unpausable_preemptive_clk_state_o      (),
        .pause_en_i                             (),
        .pause_polarity_i                       (),
        .pausable_expected_clk_state_o          (),
        .pausable_preemptive_clk_state_o        ()
    );


// Violation Control

endmodule : top
