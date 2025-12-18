/**
 *  Module: rate_tracking
 *
 *  About: 
 *
 *  Ports:
 *
**/
module rate_tracking (
    input                      common_p::clk_dom_s sys_dom_i,

    input                                          generation_en_i,
    input                                          clear_state_i,

    // ToDo: Add phase resync support using deltas
    input          clks_alot_p::recovered_events_s recovered_events_i,
    input                                          deltas_locked_in_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_delta_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_delta_i,

    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_rate_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_rate_i,

    input               clks_alot_p::clock_state_s unpausable_clk_state_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] counter_current_i,

    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] quarter_rate_target_o,
    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_rate_target_o,
    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_half_rate_o,
    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] inactive_half_rate_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Common Connections
    wire   [1:0] half_rate_condition;
    assign       half_rate_condition[0] = unpausable_clk_state_i.clk;
    assign       half_rate_condition[1] = clear_state_i || sync_rst;

    wire half_rate_trigger = sync_rst
                          || (clk_en && unpausable_clk_state_i.events.any_valid_edge && generation_en_i)
                          || (clk_en && clear_state_i);

// Target Half-Rate
    reg    [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_rate_target_current;
    logic  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_rate_target_next;
    always_comb begin : half_rate_target_next_mux
        case (half_rate_condition)
            2'b00  : half_rate_target_next = high_rate_i + counter_current_i; // Currently low, going high
            2'b01  : half_rate_target_next = low_rate_i + counter_current_i; // Currently high, going low
            2'b10  : half_rate_target_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            2'b11  : half_rate_target_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            default: half_rate_target_next = clks_alot_p::RATE_COUNTER_WIDTH'(0);
        endcase
    end
    always_ff @(posedge clk) begin
        if (half_rate_trigger) begin
            half_rate_target_current <= half_rate_target_next;
        end
    end
    assign half_rate_target_o = half_rate_target_current;

// Target Quarter-Rate
    reg    [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] quarter_rate_target_current;
    logic  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] quarter_rate_target_next;
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_quarter_rate = {1'b0, high_rate_i[(clks_alot_p::RATE_COUNTER_WIDTH)-1:1]};
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_quarter_rate = {1'b0, low_rate_i[(clks_alot_p::RATE_COUNTER_WIDTH)-1:1]};
    always_comb begin : quarter_rate_target_next_mux
        case (quarter_rate_condition)
            2'b00  : quarter_rate_target_next = high_quarter_rate + counter_current_i; // Currently low, going high
            2'b01  : quarter_rate_target_next = low_quarter_rate + counter_current_i; // Currently high, going low
            2'b10  : quarter_rate_target_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            2'b11  : quarter_rate_target_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            default: quarter_rate_target_next = clks_alot_p::RATE_COUNTER_WIDTH'(0);
        endcase
    end
    always_ff @(posedge clk) begin
        if (half_rate_trigger) begin
            quarter_rate_target_current <= quarter_rate_target_next;
        end
    end
    assign quarter_rate_target_o = quarter_rate_target_current;

// Active Half-Rate
    reg    [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_half_rate_current;
    logic  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_half_rate_next;
    always_comb begin : active_half_rate_next_mux
        case (half_rate_condition)
            2'b00  : active_half_rate_next = high_rate_i; // Currently low, going high
            2'b01  : active_half_rate_next = low_rate_i; // Currently high, going low
            2'b10  : active_half_rate_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            2'b11  : active_half_rate_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            default: active_half_rate_next = clks_alot_p::RATE_COUNTER_WIDTH'(0);
        endcase
    end
    always_ff @(posedge clk) begin
        if (half_rate_trigger) begin
            active_half_rate_current <= active_half_rate_next;
        end
    end

// Active Low-Rate
    reg    [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] inactive_half_rate_current;
    logic  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] inactive_half_rate_next;
    always_comb begin : inactive_half_rate_next_mux
        case (half_rate_condition)
            2'b00  : inactive_half_rate_next = low_rate_i; // Currently low, going high
            2'b01  : inactive_half_rate_next = high_rate_i; // Currently high, going low
            2'b10  : inactive_half_rate_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            2'b11  : inactive_half_rate_next = clks_alot_p::RATE_COUNTER_WIDTH'(0); // Reset
            default: inactive_half_rate_next = clks_alot_p::RATE_COUNTER_WIDTH'(0);
        endcase
    end
    always_ff @(posedge clk) begin
        if (half_rate_trigger) begin
            inactive_half_rate_current <= inactive_half_rate_next;
        end
    end

endmodule : rate_tracking
