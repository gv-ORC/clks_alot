module counter #(
    parameter BIT_WIDTH = 8
)(
    input  common_p::clk_dom_s sys_dom_i,
    
    input                      init_en_i,
    input                      clear_en_i,

    input                      counter_en_i,
    input                      decay_en_i,

    input      [BIT_WIDTH-1:0] seed_i,
    input      [BIT_WIDTH-1:0] growth_rate_i,
    input      [BIT_WIDTH-1:0] decay_rate_i,

    output     [BIT_WIDTH-1:0] count_o
);

    reg    [BIT_WIDTH-1:0] count_current;
    logic  [BIT_WIDTH-1:0] count_next;
    wire             [1:0] count_next_condition;
    assign                 count_next_condition[0] = init_en_i || clear_en_i || sync_rst;
    assign                 count_next_condition[1] = (decay_en_i && ~init_en_i) || clear_en_i || sync_rst;

    wire   [BIT_WIDTH-1:0] filtered_decay_rate = (count_current < decay_rate_i)
                                               ? count_current
                                               : decay_rate_i;
    always_comb begin : count_nextMux
        case (count_next_condition)
            2'b00  : count_next = count_current + growth_rate_i;
            2'b01  : count_next = seed_i;
            2'b10  : count_next = count_current - decay_rate_i;
            2'b11  : count_next = BIT_WIDTH'(0);
            default: count_next = BIT_WIDTH'(0);
        endcase
    end
    wire count_trigger = sync_rst
                      || (clk_en && counter_en_i)
                      || (clk_en && clear_en_i);
    always_ff @(posedge clk) begin
        if (count_trigger) begin
            count_current <= count_next;
        end
    end


endmodule : counter
