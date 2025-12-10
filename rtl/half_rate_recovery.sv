module half_rate_recovery (
    input  
);

// TODO: Make sure this has support for full-rate recovery when its configured as such and half-rate when it is not

// Check if the event is occuring within the right frequency band
// TODO: See if we can reduce this to just band bounds, violation bounds should be managed by lockin 
event_filtering event_filtering (
    .half_rate_limits_i         (),
    .polarity_en_i              (),
    .polarity_i                 (),
    .primary_clk_i              (),
    .current_rate_counter_i     (),
    .sense_event_i              (),
    .ignore_filtered_event_o    (),
    .polarity_filtered_event_o  (),
    .over_frequency_violation_o (),
    .under_frequency_violation_o()
);

// Lockin the state of the expected clock
lockin lockin (
    .sys_dom_i               (),
    .rate_control_en_i       (),
    .clear_state_i           (),
    .active_drift_direction_i(),
    .half_rate_limits_i      (),
    .current_rate_counter_i  (),
    .filtered_event_i        (),
    .active_rate_valid_i     (),
    .active_rate_i           (),
    .drift_detected_o        (),
    .drift_direction_o       (),
    .drift_amount_o          (),
    .update_rate_o           (),
    .locked_in_o             ()
);

// Accumulate half-rates and properly average them over time to get the active rate.
rate_tracker rate_tracker (
    .sys_dom_i          (),
    .rate_tracking_en_i (),
    .clear_state_i      (),
    .update_rate_i      (),
    .clear_rate_i       (),
    .rate_accumulator_o (),
    .active_rate_valid_o(),
    .active_rate_o      (),
);

endmodule : half_rate_recovery
