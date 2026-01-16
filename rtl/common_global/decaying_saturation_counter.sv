module decaying_saturation_counter #(
    parameter BIT_WIDTH = 8
)(
    input  common_p::clk_dom_s clk_dom_i,
    
    input                      counter_en_i,
    input                      decay_en_i,
    input                      clear_en_i,

    input      [BIT_WIDTH-1:0] growth_rate_i,
    input      [BIT_WIDTH-1:0] decay_rate_i,
    input      [BIT_WIDTH-1:0] saturation_limit_i,
    // If 1: Don't allow any more decay once `count_o` <= `plateau_limit_i`
    // If 0: Don't allow any more decay once `count_o` <= `decay_rate_i`
    input                      plateau_en_i,
    input      [BIT_WIDTH-1:0] plateau_limit_i,

    output                     plateaued_o,
    output     [BIT_WIDTH-1:0] count_o
);

    wire saturation_check = count_o >= saturation_limit_i;

    wire decay_limit = plateau_en_i
                     ? plateau_limit_i
                     : decay_rate_i;
    wire decay_limit_check = count_o < decay_limit;

    wire decay_en = decay_en_i && ~decay_limit_check;

    wire counter_en = (counter_en_i && decay_en_i && ~decay_limit_check)
                   || (counter_en_i && ~saturation_check && ~decay_en_i);

    wire [BIT_WIDTH-1:0] null_seed = BIT_WIDTH'(0);
    counter #(
        .BIT_WIDTH(BIT_WIDTH)
    ) counter (
        .clk_dom_i    (clk_dom_i),
        .counter_en_i (counter_en),
        .init_en_i    (1'b0),
        .decay_en_i   (decay_en),
        .seed_i       (null_seed),
        .growth_rate_i(growth_rate_i),
        .decay_rate_i (decay_rate_i),
        .clear_en_i   (clear_en_i),
        .count_o      (count_o)
    );

    assign plateaued_o = count_o >= plateau_limit_i;

endmodule : decaying_saturation_counter
