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

* When in full-rate mode with an odd full-rate, have an option for which edge to apply the odd half-rate


*/ 

// Half-Rate Control (High/Both)
    half_rate_recovery high_half_rate_recovery (
    
    );

// Half-Rate Control (Low)
    half_rate_recovery low_half_rate_recovery (

    );


// Pause Control

endmodule : rate_recovery
