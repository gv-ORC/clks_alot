module clock_generation (
    input          common_p::clk_dom_s sys_dom_i,

    input                              set_clock_low_i,
    input                              set_clock_high_i,

    input                              clock_active_i,
    input                              clear_state_i,
    input                              half_rate_elapsed_i,
    input                              quarter_rate_elapsed_i,

    output clks_alot_p::clock_states_s unpausable_state_o,

    input                              pause_en_i,
    input                              pause_polarity_i,
    // 1 Cycle delay to enforce proper pausing
    output clks_alot_p::clock_states_s pausable_state_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Clock State
    wire toggle_clock = clock_active_i && half_rate_elapsed_i;

    flip_flop clock_state (
        .clk_dom_s_i(sys_dom_i),
        .clear_en (set_clock_low_i),
        .set_en   (set_clock_high_i),
        .toggle_en(toggle_clock),
        .state_o  (unpausable_state_o.clk)
    );

// Pause Control
    reg  pause_active_current;
    wire pause_active_next = ~sync_rst && pause_en_i && ~clear_state_i;
    wire pause_update_check = (clk_en && ~pause_active_current && pause_en_i && pause_polarity_i && unpausable_state_o.clk)
                           || (clk_en && ~pause_active_current && pause_en_i && ~pause_polarity_i && ~unpausable_state_o.clk)
                           || (clk_en && pause_active_current && ~pause_en_i && pause_polarity_i && unpausable_state_o.clk)
                           || (clk_en && pause_active_current && ~pause_en_i && ~pause_polarity_i && ~unpausable_state_o.clk);
    wire pause_active_trigger = sync_rst
                             || (pause_update_check && clock_active_i && ~half_rate_elapsed_i)
                             || (clk_en && clear_state_i); // Clear when clock goes inactive
    always_ff @(posedge clk) begin
        if (pause_active_trigger) begin
            pause_active_current <= pause_active_next;
        end
    end

    assign unpausable_state_o.status.pause_active = 1'b0;
    assign unpausable_state_o.status.pause_duration = clks_alot_p::RATE_COUNTER_WIDTH'(0);
    assign pausable_state_o.status.pause_active = pause_active_current;
    assign pausable_state_o.status.pause_duration = clks_alot_p::RATE_COUNTER_WIDTH'(0);

// Output Buffer
    reg  paused_clock_current;
    wire paused_clock_next = (~sync_rst && unpausable_state_o.clk && ~set_clock_low_i)
                          || (~sync_rst && set_clock_high_i);
    wire paused_clock_trigger = sync_rst
                             || (clk_en && set_clock_low_i)
                             || (clk_en && set_clock_high_i)
                             || (clk_en && clock_active_i && ~pause_active_current);
    always_ff @(posedge clk) begin
        if (paused_clock_trigger) begin
            paused_clock_current <= paused_clock_next;
        end
    end

    assign pausable_state_o.clk = paused_clock_current;

// Event Generation
    event_generation unpausable_event_generation (
        .sys_dom_i           (sys_dom_i),
        .clock_active_i      (clock_active_i),
        .io_clk_i            (unpausable_state_o.clk),
        .half_rate_elapsed   (half_rate_elapsed_i),
        .quarter_rate_elapsed(quarter_rate_elapsed_i),
        .clk_events_o        (unpausable_state_o.events)
    );
    assign unpausable_state_o.locked = clock_active_i;

    wire pausable_active = clock_active_i && ~pause_active_current;
    event_generation pausable_event_generation (
        .sys_dom_i           (sys_dom_i),
        .clock_active_i      (pausable_active),
        .io_clk_i            (pausable_state_o.clk),
        .half_rate_elapsed   (half_rate_elapsed_i),
        .quarter_rate_elapsed(quarter_rate_elapsed_i),
        .clk_events_o        (pausable_state_o.events)
    );
    //TODO: Update this once lock-in is enabled
    assign pausable_state_o.status.locked = clock_active_i;

endmodule : clock_generation
