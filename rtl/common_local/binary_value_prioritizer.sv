binary_value_prioritizer #(
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
    input  [VALUE_BIT_WIDTH-1:0] data_i,

    output                       locked_in_o,
    output                       b_is_prioritized_o, // If 0, a is prioritized (state only valid when `locked_in_o` is high)
    output [VALUE_BIT_WIDTH-1:0] data_o
);

// Saturation Comparison
    wire [COUNT_BIT_WIDTH-1:0] saturation_count_a;
    wire [COUNT_BIT_WIDTH-1:0] saturation_count_b;
    wire                       b_is_greater_check = saturation_count_b > saturation_count_a;
    wire                       a_is_greater_check = saturation_count_a > saturation_count_b;

// Priorization
    reg  b_is_prioritized_current;
    wire b_is_prioritized_next = ~sync_rst && b_is_greater_check && ~clear_state_i;
    wire b_is_prioritized_trigger = sync_rst
                                 || (clk_en && we_i && a_is_greater_check)
                                 || (clk_en && we_i && b_is_greater_check)
                                 || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (b_is_prioritized_trigger) begin
            b_is_prioritized_current <= b_is_prioritized_next;
        end
    end
    assign b_is_prioritized_o = b_is_prioritized_current;

// Value A Tracking
    wire [VALUE_BIT_WIDTH-1:0] data_a;
    wire                       plateaued_a;
    binary_value_prioritizer_cell #(
        .VALUE_BIT_WIDTH(VALUE_BIT_WIDTH),
        .COUNT_BIT_WIDTH(COUNT_BIT_WIDTH)
    ) value_cell_a (
        .sys_dom_i         (sys_dom_i),
        .clear_state_i     (clear_state_i),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_limit_i   (plateau_limit_i),
        .we_i              (we_i),
        .data_i            (data_i),
        .we_have_priority_i(~b_is_prioritized_current),
        .data_o            (data_a),
        .count_plateaued_o (plateaued_a),
        .saturation_count_o(saturation_count_a)
    );

// Value B Tracking
    wire [VALUE_BIT_WIDTH-1:0] data_b;
    wire                       plateaued_b;
    binary_value_prioritizer_cell #(
        .VALUE_BIT_WIDTH(VALUE_BIT_WIDTH),
        .COUNT_BIT_WIDTH(COUNT_BIT_WIDTH)
    ) value_cell_b (
        .sys_dom_i         (sys_dom_i),
        .clear_state_i     (clear_state_i),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_limit_i   (plateau_limit_i),
        .we_i              (we_i),
        .data_i            (data_i),
        .we_have_priority_i(b_is_prioritized_current),
        .data_o            (data_b),
        .count_plateaued_o (plateaued_b),
        .saturation_count_o(saturation_count_b)
    );

// Output Assignments
    assign locked_in_o = b_is_prioritized_o
                       ? plateaued_b
                       : plateaued_a;
    assign data_o = b_is_prioritized_o
                  ? data_b
                  : data_a;

endmodule : binary_value_prioritizer
