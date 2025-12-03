/**
 *  Module: clock_recovery
 *
 *  About: 
 *
 *  Ports:
 *
**/
module clock_recovery (
    input          sys_structs::clk_domain sys_dom_i, // Expects 64Mhz

    input                                  recovery_enable_i,
    input  [(io_clk_p::CYCLE_BITWIDTH - 1):0] preemtive_output_cycle_count_i, //? Assuming that this is buffered during init
    input                                  clk_to_recover_i, // Pre-syncronized with the data to sys_dom_i

    // All outputs below come out 2 sys_dom_i cycles after the actual state changes
                                           // Pulses after 2 missed negedge events
    output                                 pause_start_detected_o,
    output                                 short_pause_complete_o,
    output                                 long_pause_complete_o,
                                           // Held high until next negedge when a pause occures too late.
    output                                 data_overflow_violation_o,
                                           // Held high until next negedge when a pause starts prematurely.
    output                                 data_underflow_violation_o,
                                           // Pulses when an edge is detected more than 1 sys clock-cycle away from what is expected
    output                                 frequency_violation_o,

    output                                 tick_output_o,
    output                                 tick_input_o
);

//* Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

//* Edge Detection
    wire clk_state;
    wire negedge_mono;
    wire bothedge_mono;

    monostable_full #(
        .BUFFERED(1'b1)
    ) clock_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(recovery_enable_i),
        .sense_i        (clk_to_recover_i),
        .prev_o         (clk_state), //! Not Used
        .posedge_mono_o (), //! Not Used
        .negedge_mono_o (negedge_mono),
        .bothedge_mono_o(bothedge_mono)
    );

//* Counters
    reg  [(io_clk_p::CYCLE_BITWIDTH - 1):0] cycle_count_current;
    wire                                 cycle_saturated = cycle_count_current == (io_clk_p::UNCERTAIN_LONG_LENGTH);
    wire [(io_clk_p::CYCLE_BITWIDTH - 1):0] cycle_count_next = (sync_rst || bothedge_mono || ~recovery_enable_i)
                                                          ? io_clk_p::CYCLE_BITWIDTH'(0)
                                                          : (cycle_count_current + io_clk_p::CYCLE_BITWIDTH'(~cycle_saturated));
    wire                                 cycle_count_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (cycle_count_trigger) begin
            cycle_count_current <= cycle_count_next;
        end
    end

    reg  [(io_clk_p::NEGEDGE_BITWIDTH - 1):0] negedge_count_current;
    wire                                   negedge_saturated = negedge_count_current == (io_clk_p::NEGEDGES_BETWEEN_SHORT_PAUSES);
    wire [(io_clk_p::NEGEDGE_BITWIDTH - 1):0] negedge_count_next = (sync_rst || pause_start_detected_o || ~recovery_enable_i)
                                                              ? io_clk_p::NEGEDGE_BITWIDTH'(0)
                                                              : (negedge_count_current + io_clk_p::NEGEDGE_BITWIDTH'(~negedge_saturated));
    wire                                   negedge_count_trigger = sync_rst || (clk_en && negedge_mono);
    always_ff @(posedge clk) begin
        if (negedge_count_trigger) begin
            negedge_count_current <= negedge_count_next;
        end
    end
    assign data_overflow_violation_o = negedge_saturated;
    assign data_underflow_violation_o = (cycle_count_current >= (io_clk_p::PAUSE_START_LENGTH - 1))
                                      && (negedge_count_current < io_clk_p::NEGEDGES_BETWEEN_SHORT_PAUSES - 2);
    wire   clock_in_range = negedge_count_current < io_clk_p::NEGEDGES_BETWEEN_SHORT_PAUSES;
    assign frequency_violation_o = (clk_active_current && (cycle_count_current < (io_clk_p::MINIMUM_EDGE_CYCLE_COUNT - 1)))
                                || (clk_active_current && (cycle_count_current > (io_clk_p::MAXIMUM_EDGE_CYCLE_COUNT - 1)) && clock_in_range);

//* Pause Start Control
    assign pause_start_check = cycle_count_current == (io_clk_p::PAUSE_START_LENGTH - 1);
    monostable_full #(
        .BUFFERED(1'b1)
    ) pause_start_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(recovery_enable_i),
        .sense_i        (pause_start_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (pause_start_detected_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );

//* Short Pause Control
    wire short_pause_check = cycle_count_current == (io_clk_p::UNCERTAIN_SHORT_LENGTH - 1);
    monostable_full #(
        .BUFFERED(1'b1)
    ) short_pause_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(recovery_enable_i),
        .sense_i        (short_pause_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (short_pause_complete_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );

//* Long Pause Control
    wire long_pause_check = cycle_count_current == (io_clk_p::UNCERTAIN_LONG_LENGTH - 1);
    monostable_full #(
        .BUFFERED(1'b1)
    ) long_pause_edge_detection (
        .sys_dom_i      (sys_dom_i),
        .monostable_en_i(recovery_enable_i),
        .sense_i        (long_pause_check),
        .prev_o         (), //! Not Used
        .posedge_mono_o (long_pause_complete_o),
        .negedge_mono_o (), //! Not Used
        .bothedge_mono_o()  //! Not Used
    );


//* Data Transition Control
    /*
    Recovered  Clock: ----_-_-
    Negedge Count LSB:   00001100
    */
    // Tick Output (Pulse on Negedge Count LSB: 0 -> 1, preemptively to align with raw bus signals)
    // `preemtive_output_cycle_count_i` is offset by 1 to compensate for the extra cycle used in clock generation for monostable generator
    wire   preemptive_check = cycle_count_current == (TARGET_EDGE_CYCLE_COUNT - preemtive_output_cycle_count_i - 2);
    wire   tick_output_check =  ~negedge_count_current[0] && preemptive_check && clock_in_range && clk_state;
    reg    tick_output_delay_current;
    wire   tick_output_delay_next = ~sync_rst && tick_output_check && recovery_enable_i;
    wire   tick_output_delay_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (tick_output_delay_trigger) begin
            tick_output_delay_current <= tick_output_delay_next;
        end
    end
    assign tick_output_o = tick_output_delay_current;


    // Tick Input (Pulse on Negedge Count LSB: 1 -> 0)
    wire   tick_input_check = negedge_count_current[0] && negedge_mono && clock_in_range;
    reg    tick_input_delay_current;
    wire   tick_input_delay_next = ~sync_rst && tick_input_check && recovery_enable_i;
    wire   tick_input_delay_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (tick_input_delay_trigger) begin
            tick_input_delay_current <= tick_input_delay_next;
        end
    end
    assign tick_input_o = tick_input_delay_current;

endmodule : clock_recovery
