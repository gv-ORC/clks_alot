module pause_control (
    input              common_p::clk_dom_s sys_dom_i,

    input                                  generation_en_i,

    input  clks_alot_p::generated_events_s clk_events_i,
    input                                  io_clk_i,
    input                                  io_clk_locked_i,

    input                                  pause_en_i,
    input                                  pause_polarity_i,

    output      clks_alot_p::clock_state_s pausable_clock_o
);

/*
Allow `pause_en_i` to stay high without reacting, until the clock polarity matches `pause_polarity_i`
*/
// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Pause Control
    reg  pause_active_current;
    wire pause_active_next = ~sync_rst && pause_en_i;
    wire pause_active_trigger = sync_rst
                             || (clk_en && pause_en_i && ~(io_clk_i ^ pause_polarity_i))
                             || (clk_en && pause_active_current && pause_polarity_i && clk_events_i.falling_edge);
    always_ff @(posedge clk) begin
        if (pause_active_trigger) begin
            pause_active_current <= pause_active_next;
        end
    end
    wire pause_waiting_check = ~pause_active_current && pause_en_i;

    reg  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] pause_duration_current;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] pause_duration_next = (sync_rst || pause_waiting_check)
                                                                     ? clks_alot_p::RATE_COUNTER_WIDTH'(0)
                                                                     : (pause_duration_current + clks_alot_p::RATE_COUNTER_WIDTH'(1));
    wire pause_duration_trigger = sync_rst
                               || (clk_en && pause_waiting_check)
                               || (clk_en && pause_active_current && pause_polarity_i && clk_events_i.rising_edge)
                               || (clk_en && pause_active_current && ~pause_polarity_i && clk_events_i.falling_edge);
    always_ff @(posedge clk) begin
        if (pause_duration_trigger) begin
            pause_duration_current <= pause_duration_next;
        end
    end

    assign pausable_clock_o.events = pause_active_current
                                   ? clks_alot_p::generated_events_s'(0)
                                   : clk_events_i;
    assign pausable_clock_o.clk = pause_active_current
                                ? pause_polarity_i
                                : io_clk_i;
    assign pausable_clock_o.status.pause_active = pause_active_current;
    assign pausable_clock_o.status.pause_duration = pause_duration_current;
    assign pausable_clock_o.status.locked = io_clk_locked_i;

endmodule : pause_control
