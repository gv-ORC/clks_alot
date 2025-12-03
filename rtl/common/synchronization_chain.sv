/**
 *  Module: synchronization_chain
 *
 *  About: 
 *
 *  Ports:
 *
**/
module synchronization_chain #(
    parameter CHAIN_DEPTH = 4,
    parameter CHAIN_WIDTH = 4
)(
    input  sys_structs::clk_domain sys_dom_i, // Ignores `clk_en` and `sync_rst`

    input        [CHAIN_WIDTH-1:0] data_i,

    input        [CHAIN_WIDTH-1:0] data_o
);

//* Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

//* Sync Chain
    genvar buffer_index;
    wire [CHAIN_DEPTH-1:0][CHAIN_WIDTH-1:0] read_vector;
    generate
        for (buffer_index = 0; buffer_index < CHAIN_DEPTH; buffer_index = buffer_index + 1) begin : reg_gen
            reg  [CHAIN_WIDTH-1:0] buffer_current;
            wire [CHAIN_WIDTH-1:0] buffer_next = (buffer_index == 0)
                                               ? data_i
                                               : read_vector[buffer_index-1];
            always_ff @(posedge clk) begin
                buffer_current <= buffer_next;
            end
            assign read_vector[buffer_index] = buffer_current;
        end
    endgenerate

    assign data_o = read_vector[CHAIN_DEPTH-1];

endmodule : synchronization_chain
