/**
 *  Module: regfile
 *
 *  About: 
 *
 *  Ports:
 *
**/
module regfile #(
    parameter NUM_REG = 8,
    parameter BITWIDTH = 8,
    // Do not modify below
    parameter ADDR_WIDTH = $clog2(NUM_REG)
)(
    input                   clk,
    input                   clk_en,
    input                   sync_rst,

    input  [ADDR_WIDTH-1:0] reg_addr_i,
    input    [BITWIDTH-1:0] reg_data_i,
    input                   reg_we_i,
    output   [BITWIDTH-1:0] reg_data_o,

    input    [BITWIDTH-1:0] acc_data_i,
    input                   acc_we_i,
    output   [BITWIDTH-1:0] acc_data_o
);

// Registers
    logic [NUM_REG-1:0] decoded_reg;
    always_comb begin
        decoded_reg = NUM_REG'(0);
        decoded_reg[reg_addr_i] = 1'b1;
    end

    genvar reg_index;
    wire [NUM_REG-1:0][BITWIDTH-1:0] read_vec;
    generate
        for (reg_index = 0; reg_index < NUM_REG; reg_index = reg_index + 1) begin : reg_gen
            if (reg_index == 0) begin
                assign read_vec[reg_index] = BITWIDTH'(0);
            end
            else begin
                wire local_we = reg_we_i && decoded_reg[reg_index];
                regfile_cell #(
                    .BITWIDTH(8)
                ) register (
                    .clk     (clk),
                    .clk_en  (clk_en),
                    .sync_rst(sync_rst),
                    .data_i  (reg_data_i),
                    .we_i    (local_we),
                    .data_o  (read_vec[reg_index])
                );
            end
        end
    endgenerate
    assign reg_data_o = read_vec[reg_addr_i];

// Accumulator
    reg  [BITWIDTH-1:0] accumulator_current;
    wire [BITWIDTH-1:0] accumulator_next = sync_rst
                                         ? BITWIDTH'(0)
                                         : acc_data_i;
    wire                accumulator_trigger = sync_rst
                                           || (clk_en && acc_we_i);
    always_ff @(posedge clk) begin
        if (accumulator_trigger) begin
            accumulator_current <= accumulator_next;
        end
    end
    assign acc_data_o = accumulator_current;

endmodule : regfile
