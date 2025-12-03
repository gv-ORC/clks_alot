/**
 *  Module: input_bit_shifter
 *
 *  About: 
 *
 *  Ports:
 *
**/
module input_bit_shifter #(
    parameter SHIFT_DEPTH = 4,
    parameter SHIFT_WIDTH = 4
)(
    input             sys_structs::clk_domain sys_dom_i,
    
    input                                     shift_en_i,
    input                                     clear_en_i,
    input                   [SHIFT_DEPTH-1:0] data_i,

    output [SHIFT_DEPTH-1:0][SHIFT_WIDTH-1:0] data_o
);

//* Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

//* Shifter
    genvar buffer_index;
    wire [SHIFT_DEPTH-1:0][SHIFT_WIDTH-1:0] data_o;
    generate
        for (buffer_index = 0; buffer_index < SHIFT_DEPTH; buffer_index = buffer_index + 1) begin : reg_gen
            reg  [SHIFT_WIDTH-1:0] buffer_current;
            wire [SHIFT_WIDTH-1:0] buffer_next;
            if (buffer_index == 0) begin
                assign buffer_next = sync_rst
                                   ? SHIFT_WIDTH'(0)
                                   : data_i;
            end
            else begin
                assign buffer_next = sync_rst
                                   ? SHIFT_WIDTH'(0)
                                   : data_o[buffer_index - 1];
            end
            wire                   buffer_trigger = sync_rst
                                                 || (clk_en && shift_en_i)
                                                 || (clk_en && clear_en_i);
            always_ff @(posedge clk) begin
                if (buffer_trigger) begin
                    buffer_current <= buffer_next;
                end
            end

            assign data_o[buffer_index] = chain_buffer_current;
        end
    endgenerate

endmodule : input_bit_shifter
