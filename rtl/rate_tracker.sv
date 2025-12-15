module rate_tracker (
    input                      common_p::clk_dom_s sys_dom_i,

    input                                          rate_tracking_en_i,
    input                                          clear_state_i,

    input                                          update_rate_i,
    input                                          clear_rate_i,

    input                                          drift_detected_o, // For averaging
    input           clks_alot_p::drift_direction_e drift_direction_o, // For averaging
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_amount_o, // For averaging

    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rate_accumulator_o,
    output                                         active_rate_valid_o,
    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_rate_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Rate Accumulator
    reg  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rate_accumulator_current;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rate_accumulator_next = (sync_rst || update_rate_i || clear_rate_i || clear_state_i)
                                                                       ? clks_alot_p::RATE_COUNTER_WIDTH'(0)
                                                                       : (rate_accumulator_current + clks_alot_p::RATE_COUNTER_WIDTH'(1));
    wire                                         rate_accumulator_trigger = sync_rst
                                                                         || (clk_en && rate_tracking_en_i)
                                                                         || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (rate_accumulator_trigger) begin
            rate_accumulator_current <= rate_accumulator_next;
        end
    end

    assign rate_accumulator_o = rate_accumulator_current;

// Rate Valid
    reg  rate_valid_current;
    wire rate_valid_next = ~sync_rst && update_rate_i;
    wire rate_valid_trigger = sync_rst || (clk_en && rate_tracking_en_i);
    always_ff @(posedge clk) begin
        if (rate_valid_trigger) begin
            rate_valid_current <= rate_valid_next;
        end
    end

    assign active_rate_valid_o = rate_valid_current;

// Rate Averaging
    rate_averaging rate_averaging (
        //TODO: Build this module
    );

endmodule : rate_tracker
