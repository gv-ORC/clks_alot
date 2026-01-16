module pausable_clock (
    input                     common_p::clk_dom_s sys_dom_i,
    
    input                                         generation_en_i,
    input                                         init_i,
    input                                         starting_polarity_i,
    input                                         locked_i,

    input                                         half_toggle_event_i,

    output             clks_alot_p::clock_state_s unpausable_clock_o,

    input                                         pause_en_i,
    input                                         pause_polarity_i,
    output             clks_alot_p::clock_state_s pausable_clock_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Clock DFF
    reg  clock_current;
    wire clock_next = (init_i || sync_rst)
                    ? starting_polarity_i
                    : ~clock_current;
    wire clock_trigger = sync_rst
                      || (clk_en && init_i)
                      || (clk_en && sync_rst)
                      || (clk_en && generation_en_i && half_toggle_event_i);
    always_ff @(posedge clk) begin
        if (clock_trigger) begin
            clock_current <= clock_next;
        end
    end

// Unpausable Control
    event_generation unpausable_event_generation (
        .sys_dom_i             (sys_dom_i),
        .clock_active_i        (generation_en_i),
        .io_clk_i              (clock_current),
        .half_rate_elapsed_i   (half_toggle_event_i),
        // Quarter rates are not supported at this time.
        .quarter_rate_elapsed_i(1'b0),
        .clk_events_o          (unpausable_clock_o.events)
    );
    assign unpausable_clock_o.clk = clock_current;
    assign unpausable_clock_o.status.pause_active = 1'b0;
    assign unpausable_clock_o.status.pause_duration = clks_alot_p::RATE_COUNTER_WIDTH'(0);
    assign unpausable_clock_o.status.locked = locked_i;

// Pause Control (Only mutes pausable output.... Pause needs to start in the Preemptive, then goes into the expected... so they can stop on the same edge)
    pause_control pause_control (
        .sys_dom_i       (sys_dom_i),
        .generation_en_i (generation_en_i),
        .clk_events_i    (unpausable_clock_o.events),
        .io_clk_i        (unpausable_clock_o.clk),
        .io_clk_locked_i (unpausable_clock_o.status.locked),
        .pause_en_i      (pause_en_i),
        .pause_polarity_i(pause_polarity_i),
        .pausable_clock_o(pausable_clock_o)
    );

endmodule : pausable_clock
