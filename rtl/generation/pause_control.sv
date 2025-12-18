module pause_control (
    input              common_p::clk_dom_s sys_dom_i,

    input                                  generation_en_i,

    input  clks_alot_p::generated_events_s clk_events_i,
    input                                  io_clk_i,

    input                                  pause_en_i,
    input                                  pause_polarity_i,

    output      clks_alot_p::clock_state_s pausable_clock_o
);



endmodule : pause_control
