module rate_recovery (

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

// Half-Rate Control (High/Both)
    half_rate_recovery high_half_rate_recovery (
    
    );

// Half-Rate Control (Low)
    half_rate_recovery low_half_rate_recovery (

    );

// Drift Tracking
    drift_tracking drift_tracking (
        .sys_dom_i                       (sys_dom_i),
        .accumulator_en_i                (),
        .clear_state_i                   (),
        .drift_detected_i                (),
        .drift_direction_i               (),
        .max_drift_i                     (),
        .drift_acc_overflow_o            (),
        .inverse_drift_violation_o       (),
        .minimum_drift_lockout_duration_i(),
        .any_valid_edge_i                (),
        .expected_drift_req_o            (),
        .expected_drift_res_i            (),
        .expected_drift_direction_o      (),
        .preemptive_drift_req_o          (),
        .preemptive_drift_res_i          (),
        .preemptive_drift_direction_o    ()
    );

// Pause Control

endmodule : rate_recovery
