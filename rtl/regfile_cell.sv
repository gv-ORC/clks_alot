/**
 *  Module: regfile_cell
 *
 *  About: 
 *
 *  Ports:
 *
**/
module regfile_cell #(
    parameter BITWIDTH = 8
)(
    input                 clk,
    input                 clk_en,
    input                 sync_rst,

    input  [BITWIDTH-1:0] data_i,
    input                 we_i,
    output [BITWIDTH-1:0] data_o
);

    reg  [BITWIDTH-1:0] register_current;
    wire [BITWIDTH-1:0] register_next = sync_rst
                                      ? BITWIDTH'(0)
                                      : data_i;
    wire                register_trigger = sync_rst
                                        || (clk_en && we_i);
    always_ff @(posedge clk) begin
        if (register_trigger) begin
            register_current <= register_next;
        end
    end
    assign data_o = register_current;

endmodule : regfile_cell
