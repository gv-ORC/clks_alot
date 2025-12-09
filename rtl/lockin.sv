module lockin (
    input                 common_p::clk_dom_s sys_dom_i,
    
    input                                     recovery_en_i,
    input     clks_alot_p::half_rate_limits_s half_rate_limits_i,

    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] current_rate_counter_i,
    input                                     filtered_event_i,

    output    clks_alot_p::half_rate_limits_s filtered_limits_o
);

/*
    Unpausable:
        Current
        xxx{vvv<---|--->vvv}xxx
        xxx{vvvv<--|-->vvvv}xxx
        xxx{vvvvv<-|->vvvvv}xxx

    Pausable:
               At most half : Current
        xxx{vvv<---|--->vvv...vvv<---|--->vvv}xxx
        xxx{vvvv<--|-->vvvv...vvvv<--|-->vvvv}xxx
        xxx{vvvvv<-|->vvvvv...vvvvv<-|->vvvvv}xxx
    For Pausable Recovery: Skew must be set at an appropriate level for the expected drift during the longest sequence of like bits.

*/

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

/*
Have a counter that counts how many edges were within skew range.

// Current Rate - Updates every filtered edge

// Last Rate - Used to determine the validity of the next edge

// Output Assignments
    assign filtered_limits_o.;
    assign filtered_limits_o.;
    assign filtered_limits_o.;
    assign filtered_limits_o.maximum_band_minus_one = half_rate_limits_i.maximum_band_minus_one;
    assign filtered_limits_o.minimum_band_minus_one = half_rate_limits_i.minimum_band_minus_one;

endmodule : lockin
