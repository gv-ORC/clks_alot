/**
 *  Module: clock_generation
 *
 *  About: 
 *
 *  Ports:
 *
**/
module clock_generation (
    input          sys_structs::clk_domain sys_dom_i, // Expects 64Mhz

    input                                  generation_enable_i,
    input  [(io_clk_p::CYCLE_BITWIDTH - 1):0] preemtive_output_cycle_count_i, //? Assuming that this is buffered during init
    // When set, holds clock high after the next negedge of clk_o
    // When cleared, resumes the output of clk_o on its next posedge of clk_o
    input                                  pause_enable_i,
    //TODO: remove sync pulses
    output                                 sync_short_pause_complete_o,
    output                                 sync_long_pause_complete_o,
    output                                 preemtive_short_pause_complete_o,
    output                                 preemtive_long_pause_complete_o,

    // 2 Cycle delay from Generation Enable
    output                                 clk_lock_o,
    output                                 clk_o
);

//* Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

//* Cycle Counter
    reg clk_active_current;

    // Cycle Counter should reach roughly 32 before an edge
    localparam CYCLE_COUNT_WIDTH = io_clk_p::CYCLE_BITWIDTH + 1;
    reg  [(CYCLE_COUNT_WIDTH-1):0] cycle_count_current;
    wire [(CYCLE_COUNT_WIDTH-1):0] cycle_count_next = (sync_rst || ~clk_active_current)
                                                      ? CYCLE_COUNT_WIDTH'(0)
                                                      : (cycle_count_current + CYCLE_COUNT_WIDTH'(1));
    wire                           cycle_count_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (cycle_count_trigger) begin
            cycle_count_current <= cycle_count_next;
        end
    end

//* Clock Status
    wire clk_active_next = ~sync_rst && generation_enable_i;
    wire clk_active_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (clk_active_trigger) begin
            clk_active_current <= clk_active_next;
        end
    end

    reg  pause_active_current;

    reg  clk_status_current;
    wire clk_status_next = ~sync_rst
                        && (cycle_count_current[6] || ~clk_active_current || pause_active_current);
    wire clk_status_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (clk_status_trigger) begin
            clk_status_current <= clk_status_next;
        end
    end

    reg [1:0] clk_out_buffer_current;
    always_ff @(posedge clk) begin
        clk_out_buffer_current <= {clk_status_current, clk_active_current};
    end

    assign clk_lock_o = clk_out_buffer_current[0];
    assign clk_o = clk_out_buffer_current[1];

//* Pause Control
    monostable_full #(
        .BUFFERED(1'b0)
    ) clock_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(clk_active_current),
        .sense_i        (cycle_count_current[CYCLE_COUNT_WIDTH-1]),
        .prev_o         (), //! Not Used
        .posedge_mono_o (posedge_mono),
        .negedge_mono_o (negedge_mono),
        .bothedge_mono_o()
    );

    wire pause_active_next = ~sync_rst && pause_enable_i && generation_enable_i;
    wire pause_active_trigger = sync_rst
                             || (clk_en && ~generation_enable_i)
                             || (clk_en && posedge_mono && pause_active_current)
                             || (clk_en && negedge_mono && ~pause_active_current);
    always_ff @(posedge clk) begin
        if (pause_active_trigger) begin
            pause_active_current <= pause_active_next;
        end
    end

    reg  [(io_clk_p::CYCLE_BITWIDTH - 1):0] pause_duration_counter_current;
    wire                                 pause_duration_saturated = pause_duration_counter_current == io_clk_p::TARGET_LONG_LENGTH;
    wire [(io_clk_p::CYCLE_BITWIDTH - 1):0] pause_duration_counter_next = (sync_rst || ~pause_duration_counter_current)
                                                                     ? io_clk_p::CYCLE_BITWIDTH'(0)
                                                                     : (pause_duration_counter_current + io_clk_p::CYCLE_BITWIDTH'(~pause_duration_saturated));
    wire                                 pause_duration_counter_trigger = sync_rst
                                                                       || (clk_en && ~pause_active_current)
                                                                       || (clk_en && pause_active_current && negedge_mono);
    always_ff @(posedge clk) begin
        if (pause_duration_counter_trigger) begin
            pause_duration_counter_current <= pause_duration_counter_next;
        end
    end

//* Sync Pause Pulse
    wire sync_short_pause_check = (pause_duration_counter_current == (io_clk_p::TARGET_SHORT_LENGTH - 1)) && pause_active_current;
    monostable_full #(
        .BUFFERED(1'b1)
    ) sync_short_pause_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(generation_enable_i),
        .sense_i        (sync_short_pause_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (sync_short_pause_complete_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );

    wire sync_long_pause_check = (pause_duration_counter_current == (io_clk_p::TARGET_LONG_LENGTH - 1)) && pause_active_current;
    monostable_full #(
        .BUFFERED(1'b1)
    ) sync_long_pause_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(generation_enable_i),
        .sense_i        (sync_long_pause_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (sync_long_pause_complete_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );

//* Preemptive Pause Pulse
    wire [15:0] preemptive_pause_duration = pause_duration_counter_current - preemtive_output_cycle_count_i;

    wire preemptive_short_pause_check = (preemptive_pause_duration == (io_clk_p::TARGET_SHORT_LENGTH - 1)) && pause_active_current;
    monostable_full #(
        .BUFFERED(1'b1)
    ) preemptive_short_pause_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(generation_enable_i),
        .sense_i        (preemptive_short_pause_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (preemtive_short_pause_complete_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );

    wire preemptive_long_pause_check = (preemptive_pause_duration == (io_clk_p::TARGET_LONG_LENGTH - 1)) && pause_active_current;
    monostable_full #(
        .BUFFERED(1'b1)
    ) preemptive_long_pause_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(generation_enable_i),
        .sense_i        (preemptive_long_pause_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (preemtive_long_pause_complete_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );

endmodule : clock_generation
