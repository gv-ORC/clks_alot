binary_value_prioritizer_cell #(
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
    wire   matches_our_cell_o = value_current == data_i;
    assign count_plateaued_o = saturation_count_o <= plateau_limit_i;

    wire   will_be_negative_check = saturation_count_o < decay_rate_i;

    wire   decay_en = we_have_priority_i
                    ? (~matches_our_cell_o && ~plateau_check && count_plateaued_o)
                    : (~matches_our_cell_o && will_be_negative_check);
    wire   clear_en = (~matches_our_cell_o && ~we_have_priority_i)
                   || clear_state_i;

    decaying_saturation_counter #(
        .COUNT_BIT_WIDTH(COUNT_BIT_WIDTH)
    ) counter (
        .sys_dom_i         (sys_dom_i),
        .counter_en_i      (we_i),
        .decay_en_i        (decay_en),
        .clear_en_i        (clear_en),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .count_o           (saturation_count_o)
    );

endmodule : binary_value_prioritizer_cell
