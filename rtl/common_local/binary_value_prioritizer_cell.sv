module binary_value_prioritizer_cell #(
    parameter VALUE_BIT_WIDTH = 8,
    parameter COUNT_BIT_WIDTH = 8
)(
    input    common_p::clk_dom_s sys_dom_i,

    input                        clear_state_i,

    input  [COUNT_BIT_WIDTH-1:0] growth_rate_i,
    input  [COUNT_BIT_WIDTH-1:0] decay_rate_i,
    input  [COUNT_BIT_WIDTH-1:0] saturation_limit_i,
    input  [COUNT_BIT_WIDTH-1:0] plateau_limit_i,

    input                        we_i,
    input  [COUNT_BIT_WIDTH-1:0] data_i,

    input                        we_have_priority_i,

    output [VALUE_BIT_WIDTH-1:0] data_o,
    output                       count_plateaued_o,
    output [COUNT_BIT_WIDTH-1:0] saturation_count_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Value Buffer
    reg  [VALUE_BIT_WIDTH-1:0] value_current;
    wire [VALUE_BIT_WIDTH-1:0] value_next = (sync_rst || clear_state_i)
                                          ? VALUE_BIT_WIDTH'(0)
                                          : data_i;
    wire                       value_trigger = sync_rst
                                            || (clk_en && we_i && ~we_have_priority_i)
                                            || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (value_trigger) begin
            value_current <= value_next;
        end
    end

    assign data_o = value_current;

// Saturation Counter
    wire   value_mismatch = value_current != data_i;

    wire   clear_en = (value_mismatch && ~we_have_priority_i && we_i)
                   || clear_state_i;

    decaying_saturation_counter #(
        .BIT_WIDTH(COUNT_BIT_WIDTH)
    ) decaying_saturation_counter (
        .clk_dom_i         (sys_dom_i),
        .counter_en_i      (we_i),
        .decay_en_i        (value_mismatch),
        .clear_en_i        (clear_en),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_en_i      (we_have_priority_i),
        .plateau_limit_i   (plateau_limit_i),
        .plateaued_o       (count_plateaued_o),
        .count_o           (saturation_count_o)
    );

endmodule : binary_value_prioritizer_cell
