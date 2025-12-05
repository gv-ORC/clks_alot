module lockin (
    input                 common_p::clk_dom_s sys_dom_i,
    
    input                                     recovery_en_i,
    input     clks_alot_p::half_rate_limits_s half_rate_limits_i,

    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] current_rate_counter_i,
    input                                     filtered_event_i,

    output    clks_alot_p::half_rate_limits_s filtered_limits_o
);

// Initialization Check
    wire init_limits;
    monostable_full #(
        .BUFFERED(1'b1)
    ) init_check (
        .clk_dom_s_i    (sys_dom_i),
        .monostable_en_i(1'b1),
        .sense_i        (recovery_en_i),
        .prev_o         (), // Not Used
        .posedge_mono_o (init_limits),
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o()  // Not Used
    );

// Maximum Violation Rate Control
    /*

    */

// Minimum Violation Rate Control

// Output Assignments
    assign filtered_limits_o.half_lockin_window_minus_one = half_rate_limits_i.half_lockin_window_minus_one;
    assign filtered_limits_o.maximummaximum_violation_minus_one = lock_in
    assign filtered_limits_o.maximumminimum_violation_minus_one = lock_in
    assign filtered_limits_o.maximum_band_minus_one = half_rate_limits_i.maximum_band_minus_one;
    assign filtered_limits_o.minimum_band_minus_one = half_rate_limits_i.minimum_band_minus_one;

endmodule : lockin
