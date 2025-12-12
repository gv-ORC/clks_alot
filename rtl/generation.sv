module generation (
    input                 common_p::clk_dom_s sys_dom_i,

    //? Generation
    input                                     set_polarity_i,
    input                                     starting_polarity_i,

    input                                     generation_en_i, // When this goes low, clock will stop on the next starting_polarity
    output                                    busy_o,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] expected_half_rate_minus_two_i, // change every half-rate pulse, and you can get PWM
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] expected_quarter_rate_minus_one_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] preemptive_half_rate_minus_one_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] preemptive_quarter_rate_minus_one_i,

    //? Recovery - To accomodate for skew/drift
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] sync_cycle_offset_i,
    input          clks_alot_p::clock_state_s actual_clk_state_i, // for "Clock came too Early"

    //? Unpausable Output
    output         clks_alot_p::clock_state_s unpausable_expected_clk_state_o,
    output         clks_alot_p::clock_state_s unpausable_preemptive_clk_state_o,

    //? Pausable Output
    // Pauses maintain clock phasing when enabling and disabling
    // Pauses enable & disable when clock polarity matches
    input                                     pause_en_i,
    input                                     pause_polarity_i,
    output         clks_alot_p::clock_state_s pausable_expected_clk_state_o,
    output         clks_alot_p::clock_state_s pausable_preemptive_clk_state_o,
    output                                    pause_start_violation_o,
    output                                    pause_stop_violation_o
);

/*

? Mimic Not 50-50: Low Half-Rate 2(h), High Half-Rate 2(l), Starts at (s) = 10, Rx Delay (r) = 3, Tx Delay (t) = 3, Counter(c), Drift Window (w) = 1
* Incoming - The clock signal from the pin after it has been properly syncronized and had events extracted
* Expected - Generated clock that mimics the cycle that the clock would have arrived directly at the Rx Pin
*          > Seed Expected by: (@f1 <= (c + 2h + 2l) - r)
* Premptive - Generated clock that triggers events earlier than the pin, to account for pipeline and sync latency
*           > Seed Preemptive by: (@f1 <= (c + 2h + 2l) - r - t)

                                                                                                       Neg Drift                        Pos Drift
Incoming Edge Name:                              f0    r0    f1    r1    f2    r2    f3    r3    f4    r4(f5)   r5    f6    r6    f7      (r7)    f8    r8    f9    r9    f10
Incoming Clock:             xxxxxxx---------------______------______------______------______------______---______------______------_________------______------______------___
Counter(c):                 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51
Drift Edge Name:                                                         f2    r2    f3    r3    f4    r4(f5)    r5    f6    r6    f7     (r7)   f8    r8   f9    r9    f10
Drift Clock (fake):         xxxxxxxxxxxxxxxxxxxxxx------------------------______------______------______---______------______------_________------______------______------___
Drift Event Upper Limit:    x x x x x x x x x x x  -  -  -  -  17 17 17 17 19 19 21 21 23 23 25 25 27 27 29 32 32 34 34 36 36 38 38 40 40 40 43 43 45 45 47 47 49 49 51 51 53
Drift Target:               x x x x x x x x x x x  -  -  -  -  18 18 18 18 20 20 22 22 24 24 26 26 28 28 30 31 31 33 33 35 35 37 37 39 39 39 42 42 44 44 46 46 48 48 50 50 52
Drift Event Lower Limit:    x x x x x x x x x x x  -  -  -  -  19 19 19 19 21 21 23 23 25 25 27 27 29 29 31 30 30 32 32 34 34 36 36 38 38 38 41 41 43 43 45 45 47 47 49 49 51
Expected Edge Name:                                                         f3    r3    f4    r4    f5    r5(f6)   r6    f7    r7    f8      (r8)    f9   r9    f10   r10
Expected Clock:             xxxxxxxxxxxxxxxxxxxxxx---------------------------______------______------______---______------______------_________------______------______------
Expected Half-Rate Limit:   x x x x x x x x x x x  -  -  -  -  -  19 19 19 19 21 21 23 23 25 25 27 27 29 29 31 32 32 34 34 36 36 38 38 40 40 41 43 43 45 45 47 47 49 49 51 51
Expected High Half-Rate:    x x x x x x x x x x x  -  -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Expected Low Half-Rate:     x - - - - - - - - - -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Preemptive Edge Name:                                              f3    r3    f4    r4    f5    r5    f6    r6(f7)   r7    f8    r8    f9      (f9)    f10   r10   f11   r11
Preemptive Clock:           xxxxxxxxxxxxxxxxxxxxxx------------------______------______------______------______---______------______------_________------______------______---
Preemptive Half-Rate Limit: x x x x x x x x x x x  -  -  -  16 16 16 18 18 20 20 22 22 24 24 26 26 28 28 30 30 32 33 33 35 35 37 37 39 39 41 41 42 44 44 46 46 48 48 50 50 52
Preemptive High Half-Rate:  x x x x x x x x x x x  -  -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Preemptive Low Half-Rate:   x - - - - - - - - - -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2

*/

// Counter
    reg  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_count_current;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_count_next = (sync_rst || clear_state_i)
                                                                       ? clks_alot_p::RATE_COUNTER_WIDTH'(0)
                                                                       : (generation_count_current + clks_alot_p::RATE_COUNTER_WIDTH'(1));
    wire                                         generation_count_trigger = sync_rst
                                                                         || (clk_en && generation_en_i)
                                                                         || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (generation_count_trigger) begin
            generation_count_current <= generation_count_next;
        end
    end


// Next Expected Half-Rate Limit (Quarter-Rate is calculated off of this)
/*
Reacts instantly to incoming events.
Uses incoming events to calculate drifts.
Hold last Limit to check for the late-half of the drift window.
Detects and Forwards Drift Events
*/

// Lockin the state of the expected clock - Checks for High and Low rates together or Full rates if that is configured
//TODO: Refactor to support new architecture... and to include support for skipped-events during pausable data
//TODO:                                         ^ `~drift_detected && event` will support skipped-events,
//TODO:                                            as long as rate accumulator is reset by expected events
//TODO:                                       ! ^^^^^^^^ ! Already does this, with the same caveat ! ^^^^^^^^^ !
    lockin lockin (
        .sys_dom_i                (),
        .lockin_en_i              (),
        .clear_state_i            (),
        .active_drift_direction_i (),
        .half_rate_limits_i       (),
        .rate_accumulator_i       (),
        .filtered_event_i         (),
        .polarity_filtered_event_i(),
        .active_rate_valid_i      (),
        .active_rate_i            (),
        .drift_detected_o         (),
        .drift_direction_o        (),
        .drift_amount_o           (),
        .update_rate_o            (),
        .clear_rate_o             (),
        .locked_in_o              (),
        .rate_violation_o         ()
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

// Next Preemptive Half-Rate Limit (Quarter-Rate is calculated off of this)
/*
Reacts to drift events - Allows drifts to offset the next limit during preemptive events. 
Uses active High Half-Rate and Low Half-Rate during event updates.
*/

endmodule : generation
