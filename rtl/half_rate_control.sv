module half_rate_control (
    input                       common_p::clk_dom_s sys_dom_i,

    input                                           rate_control_en_i,
    input                                           clear_state_i,

    input  clks_alot_p::SOME_STRUCT configuration_i, // TODO

    input                                           drift_detected_i,
    output           clks_alot_p::drift_direction_e drift_direction_i,
    input                                           any_valid_edge_i,

    output clks_alot_p::SOME_STRUCT violations_o, // TODO:

    output clks_alot_p::SOME_STRUCT filtered_limits_o,

    output                                          expected_drift_req_o,
    input                                           expected_drift_res_i,
    output           clks_alot_p::drift_direction_e expected_drift_direction_o,

    output                                          preemptive_drift_req_o,
    input                                           preemptive_drift_res_i,
    output           clks_alot_p::drift_direction_e preemptive_drift_direction_o
);

/*
    Pausable signals are either clocks that can be paused between transactions, or data that needs its clock recovered

    SINGLE_CONTINUOUS - Lockin by grabbing the rate and only allowing a certain amount of skew.
      SINGLE_PAUSABLE - Update lockin when the new rate is less than half of the current rate, but still within the bounds.
       DIF_CONTINUOUS - Lockin by halving the captured full rate, allowing a certain amount of skew.
         DIF_PAUSABLE - Update lockin when the new rate is less than half of the current rate, but still within the bounds.
      QUAD_CONTINUOUS - Lockin by halving the captured full rate, allowing a certain amount of skew.
                        Force Use of `*.any_valid_edge`
        QUAD_PAUSABLE - Update lockin when the new rate is less than half of the current rate, but still within the bounds. 
                        Force Use of `*.any_valid_edge`

    For non-single modes: Violation range will be anything between below half-rate

    ? Polarity
     >    Disabled - Update Rate on `*.any_valid_edge`
     > Enabled Pos - Enable Counter on `*.rising_edge`, Update Rate on `*.falling_edge`
     > Enabled Neg - Enable Counter on `*.falling_edge`, Update Rate on `*.rising_edge`
*/

// Lockin
    lockin lockin (
        .sys_dom_i             (sys_dom_i),
        .recovery_en_i         (),
        .half_rate_limits_i    (),
        .current_rate_counter_i(),
        .filtered_event_i      (),
        .filtered_limits_o     ()
    );

// Event Filtering
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

// Rate Recovery
    rate_recovery rate_recovery (
        .sys_dom_i             (),
        .recovery_en_i         (),
        .recovery_config_i     (),
        .recovered_events_i    (),
        .current_rate_o        (),
        .recovered_half_rates_o()
    );

// Pause Recovery
    pause_recovery pause_recovery (

    ):

// Half-Rate Counter

endmodule : half_rate_control
