module decaying_saturation_counter #(
    parameter BIT_WIDTH = 8
)(
    input  common_p::clk_dom_s sys_dom_i,
    
    input                      counter_en_i,
    input                      decay_en_i,
    input                      clear_en_i,

    input      [BIT_WIDTH-1:0] growth_rate_i,
    input      [BIT_WIDTH-1:0] decay_rate_i,
    input      [BIT_WIDTH-1:0] saturation_limit_i,

    output     [BIT_WIDTH-1:0] count_o
);

    wire saturation_check = count_o >= saturation_limit_i;
    wire counter_en = (counter_en_i && decay_en_i)
                   || (counter_en_i && ~saturation_check);

    wire [BIT_WIDTH-1:0] null_seed = BIT_WIDTH'(0);
    counter #(
        .BIT_WIDTH(BIT_WIDTH)
    ) counter (
        .sys_dom_i    (sys_dom_i),
        .counter_en_i (counter_en),
        .init_en_i    (1'b0),
        .decay_en_i   (decay_en_i),
        .seed_i       (null_seed),
        .growth_rate_i(growth_rate_i),
        .decay_rate_i (decay_rate_i),
        .clear_en_i   (clear_en_i),
        .count_o      (count_o)
    );

endmodule : decaying_saturation_counter
