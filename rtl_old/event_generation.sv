module event_generation (
    input                   common_p::clk_dom_s sys_dom_i,

    input                                     clock_active_i,

    input                                     io_clk_i,
    input                                     half_rate_elapsed_i,
    input                                     quarter_rate_elapsed_i,

    output        clks_alot_p::generated_events_s clk_events_o
);

    wire rising_edge_check = ~io_clk_i && half_rate_elapsed_i;
    monostable_full #(
        .BUFFERED(1'b1)
    ) rising_edge (
        .clk_dom_s_i      (sys_dom_i),
        .monostable_en_i(clock_active_i),
        .sense_i        (rising_edge_check),
        .prev_o         (), // Not Used
        .posedge_mono_o (clk_events_o.rising_edge),
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o()  // Not Used
    );

    wire stable_high_check = io_clk_i && quarter_rate_elapsed_i;
    monostable_full #(
        .BUFFERED(1'b1)
    ) stable_high (
        .clk_dom_s_i      (sys_dom_i),
        .monostable_en_i(clock_active_i),
        .sense_i        (stable_high_check),
        .prev_o         (), // Not Used
        .posedge_mono_o (clk_events_o.stable_high),
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o()  // Not Used
    );

    wire falling_edge_check = io_clk_i && half_rate_elapsed_i;
    monostable_full #(
        .BUFFERED(1'b1)
    ) falling_edge (
        .clk_dom_s_i      (sys_dom_i),
        .monostable_en_i(clock_active_i),
        .sense_i        (falling_edge_check),
        .prev_o         (), // Not Used
        .posedge_mono_o (clk_events_o.falling_edge),
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o()  // Not Used
    );

    wire stable_low_check = ~io_clk_i && quarter_rate_elapsed_i;
    monostable_full #(
        .BUFFERED(1'b1)
    ) stable_low (
        .clk_dom_s_i      (sys_dom_i),
        .monostable_en_i(clock_active_i),
        .sense_i        (stable_low_check),
        .prev_o         (), // Not Used
        .posedge_mono_o (clk_events_o.stable_low),
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o()  // Not Used
    );

endmodule : event_generation
