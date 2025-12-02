/**
 *  Module: clock_control
 *
 *  About: 
 *
 *  Ports:
 *
**/
module clock_control (
    input          sys_structs::clk_domain clk_dom_i,
);

//! NOTE: `syncronization_chain` Ignores `clk_en` and `sync_rst` -- as I call it "blind"

//* Input Syncronization
    io_clk_p::interface_s metastablized_input;
    synchronization_chain #(
        .Chain_Depth(4),
        .Chain_Width(io_clk_p::INTERFACE_WIDTH)
    ) input_sync (
        .clk_dom_i(clk_dom),
        .data_i   (interface_i),
        .data_o   (metastablized_input)
    );

    // Ignore .clk of output struct
    // Further delay data and address to match clock recovery
    syncronization_chain #(
        .Chain_Depth(2),
        .Chain_Width(io_clk_p::INTERFACE_WIDTH)
    ) post_clk_recovery_sync (
        .clk_dom_i(clk_dom),
        .data_i   (metastablized_input),
        .data_o   (synchronized_input_o)
    );

//*  Clock Generation
    io_clk_p::interface_clock_s raw_generated_clock;
    clock_generation clk_generation (
        .clk_dom_i                       (clk_dom),
        .generation_enable_i             (generation_enable_i),
        .pause_enable_i                  (pause_enable_i),
        .sync_short_pause_complete_o     (sync_short_pause_complete_o),
        .sync_long_pause_complete_o      (sync_long_pause_complete_o),
        .preemtive_short_pause_complete_o(preemtive_short_pause_complete_o),
        .preemtive_long_pause_complete_o (preemtive_long_pause_complete_o),
        .clk_lock_o                      (raw_generated_clock.clk_lock),
        .clk_o                           (raw_generated_clock.clk)
    );

    // Delay generated clock to match clock recovery
    syncronization_chain #(
        .Chain_Depth(2),
        .Chain_Width(io_clk_p::INTERFACE_CLOCK_WIDTH)
    ) post_clk_recovery_sync (
        .clk_dom_i(clk_dom),
        .data_i   (raw_generated_clock),
        .data_o   (generated_clock)
    );

//*  Clock Recover
    wire clk_to_recover = raw_generated_clock.clk_lock
                        ? raw_generated_clock.clk
                        : metastablized_input.clk;

    clock_recovery clk_recovery (
        .clk_dom_i                     (clk_dom),
        .recovery_enable_i             (recovery_enable_i),
        .preemtive_output_cycle_count_i(preemtive_output_cycle_count_i),
        .clk_to_recover_i              (clk_to_recover),
        .pause_start_detected_o        (pause_start_detected_o),
        .short_pause_complete_o        (short_pause_complete_o),
        .long_pause_complete_o         (long_pause_complete_o),
        .data_overflow_violation_o     (data_overflow_violation_o),
        .data_underflow_violation_o    (data_underflow_violation_o),
        .frequency_violation_o         (frequency_violation_o),
        .tick_output_o                 (tick_output_o),
        .tick_input_o                  (tick_input_o)
    );

endmodule : clock_control
