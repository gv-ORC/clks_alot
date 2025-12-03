module clock_state (
    input  common_p::clk_dom sys_dom_i,

    input                    set_clock_low_i,
    input                    set_clock_high_i,

    input                    clock_active_i,
    input                    toggle_en_i,

    input                    pause_en_i,
    input                    pause_polarity_i,

    output                   pause_active_o,
    // 1 Cycle delay to enforce proper pausing
    output                   state_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Clock State
    wire toggle_clock = clock_active_i && toggle_en_i;
    wire local_clk_state;

    flip_flop clock_state (
        .sys_dom_i(sys_dom_i),
        .clear_en (set_clock_low_i),
        .set_en   (set_clock_high_i),
        .toggle_en(toggle_clock),
        .state_o  (local_clk_state)
    );

// Pause Control
    reg  pause_active_current;
    wire pause_active_next = ~sync_rst && pause_en_i && clock_active_i;
    wire pause_update_check = (clk_en && ~pause_active_current && pause_en_i && pause_polarity_i && local_clk_state)
                           || (clk_en && ~pause_active_current && pause_en_i && ~pause_polarity_i && ~local_clk_state)
                           || (clk_en && pause_active_current && ~pause_en_i && pause_polarity_i && local_clk_state)
                           || (clk_en && pause_active_current && ~pause_en_i && ~pause_polarity_i && ~local_clk_state);
    wire pause_active_trigger = sync_rst
                             || (pause_update_check && clock_active_i)
                             || (clk_en && ~clock_active_i); // Clear when clock goes inactive
    always_ff @(posedge clk) begin
        if (pause_active_trigger) begin
            pause_active_current <= pause_active_next;
        end
    end

    assign pause_active_o = pause_active_current;

// Output Buffer
    reg  paused_clock_current;
    wire paused_clock_next = (~sync_rst && local_clk_state && ~set_clock_low_i)
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

    assign state_o = paused_clock_current;

endmodule : clock_state
