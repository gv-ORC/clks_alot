module event_recovery (
    input              common_p::clk_dom_s sys_dom_i,

    input                                  recovery_en_i,
    // Used for differential and quad-state signals to decide which input is used to determine the primary clock edges
    // 0: io_clk_i.neg edges are forwarded, with io_clk_i.pos used for verification
    // 1: io_clk_i.pos edges are forwarded, with io_clk_i.neg used for verification
    // Use for single-ended signals to decide which input is used as the clock signal
    // 0: io_clk_i.neg used
    // 1: io_clk_i.pos used
    input                                  source_select_i,
    input              clks_alot_p::mode_e recovery_mode_i,
    
    input     clks_alot_p::recovery_pins_s io_clk_i,

    output                                 primary_clk_o,
    // 0 Cycle delay, can add a buffer if required - Input should be coming directly from a syncronization chain.
    output clks_alot_p::recovered_events_s recovered_events_o
);

    clks_alot_p::recovery_drivers_s recovery_drivers;
    assign primary_clk_o = source_select_i
                         ? io_clk_i.pos
                         : io_clk_i.neg;
    assign recovery_drivers.primary = primary_clk_o;
    assign recovery_drivers.secondary = source_select_i
                                      ? io_clk_i.neg
                                      : io_clk_i.pos;

    clks_alot_p::driver_events_s driver_events;

    monostable_full #(
        .BUFFERED(1'b0)
    ) primary_edge_detection (
        .clk_dom_i    (sys_dom_i),
        .monostable_en_i(recovery_en_i),
        .sense_i        (recovery_drivers.primary),
        .prev_o         (), // Not Used
        .posedge_mono_o (driver_events.primary_rising_edge),
        .negedge_mono_o (driver_events.primary_falling_edge),
        .bothedge_mono_o(driver_events.primary_either_edge)
    );

    monostable_full #(
        .BUFFERED(1'b0)
    ) secondary_edge_detection (
        .clk_dom_i      (sys_dom_i),
        .monostable_en_i(recovery_en_i),
        .sense_i        (recovery_drivers.secondary),
        .prev_o         (), // Not Used
        .posedge_mono_o (driver_events.secondary_rising_edge),
        .negedge_mono_o (driver_events.secondary_falling_edge),
        .bothedge_mono_o(driver_events.secondary_either_edge)
    );

    event_selection event_selection (
        .sys_dom_i         (sys_dom_i),
        .recovery_en_i     (recovery_en_i),
        .recovery_mode_i   (recovery_mode_i),
        .io_clk_i          (io_clk_i)
        .driver_events_i   (driver_events),
        .recovered_events_o(recovered_events_o)
    );

endmodule : event_recovery
