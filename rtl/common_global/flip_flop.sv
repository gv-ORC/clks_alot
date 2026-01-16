module flip_flop (
    input  common_p::clk_dom_s clk_dom_i,

    // Control Priority:
    // 1. Clear
    // 2. Set
    // 3. Toggle
    input                    clear_en,
    input                    set_en,
    input                    toggle_en,

    output                   state_o
);

// Clock Configuration
    wire clk = clk_dom_i.clk;
    wire clk_en = clk_dom_i.clk_en;
    wire sync_rst = clk_dom_i.sync_rst;

// Flip-Flop State
    reg  state_current;
    wire state_next = (~sync_rst && set_en && ~clear_en)
                   || (~sync_rst && ~state_current && toggle_en && ~clear_en);
    wire state_trigger = sync_rst
                      || (clk_en && toggle_en)
                      || (clk_en && set_en)
                      || (clk_en && clear_en);
    always_ff @(posedge clk) begin
        if (state_trigger) begin
            state_current <= state_next;
        end
    end

    assign state_o = state_current;

endmodule : flip_flop
