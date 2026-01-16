module test_clk (
    input                      common_p::clk_dom_s sys_dom_i,

    input                                          init_i,
    input                                          starting_polarity_i,
    input                                          generation_en_i,

    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_rate_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_rate_i,

    output                                         clk_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Counter
    reg  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] counter_current;
    wire high_limit_reached;
    wire low_limit_reached;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] counter_next = (sync_rst || high_limit_reached || low_limit_reached || init_i)
                                                              ? clks_alot_p::RATE_COUNTER_WIDTH'(0)
                                                              : (counter_current + clks_alot_p::RATE_COUNTER_WIDTH'(1));
    wire        counter_trigger = sync_rst
                               || (clk_en && generation_en_i)
                               || (clk_en && init_i);
    always_ff @(posedge clk) begin
        if (counter_trigger) begin
            counter_current <= counter_next;
        end
    end

    assign high_limit_reached = (counter_current == (high_rate_i - 1)) && clk_o;
    assign low_limit_reached = (counter_current == (low_rate_i - 1)) && ~clk_o;

// Clock DFF
    reg  clk_state_current;
    wire clk_state_next = (~sync_rst && ~clk_state_current && ~init_i)
                       || (~sync_rst && init_i && starting_polarity_i);
    wire clk_state_trigger = sync_rst
                          || (clk_en && generation_en_i && high_limit_reached)
                          || (clk_en && generation_en_i && low_limit_reached)
                          || (clk_en && init_en_i);
    always_ff @(posedge clk) begin
        if (clk_state_trigger) begin
            clk_state_current <= clk_state_next;
        end
    end
    assign clk_o = clk_state_current;

endmodule : test_clk
