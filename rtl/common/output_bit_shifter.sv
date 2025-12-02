/**
 *  Module: output_bit_shifter
 *
 *  About: 
 *
 *  Ports:
 *
**/
module output_bit_shifter #(
    parameter INPUT_DEPTH = 16,
    parameter SHIFT_DEPTH = 1
)(
    input  sys_structs::clk_domain clk_dom_i,
    
    input                          we_en_i,
    input                          shift_en_i,
    input                          clear_en_i,
    input        [INPUT_DEPTH-1:0] data_i,

    output                         empty_o,
    output       [SHIFT_DEPTH-1:0] data_o
);

//* Clock Configuration
    wire clk = clk_dom_i.clk;
    wire clk_en = clk_dom_i.clk_en;
    wire sync_rst = clk_dom_i.sync_rst;

//* Common Trigger
    wire buffer_trigger = sync_rst
                       || (clk_en && we_en_i)
                       || (clk_en && shift_en_i)
                       || (clk_en && clear_en_i);

//* Data Shifter
    reg    [INPUT_DEPTH-1:0] data_buffer_current;
    logic  [INPUT_DEPTH-1:0] data_buffer_next;
    wire               [1:0] data_buffer_next_condition;
    assign                   data_buffer_next_condition[0] = we_en_i;
    assign                   data_buffer_next_condition[1] = clear_en_i || sync_rst;
    always_comb begin : data_buffer_nextMux
        case (data_buffer_next_condition)
            2'b00  : data_buffer_next = {SHIFT_DEPTH'(0), data_buffer_current[INPUT_DEPTH-1:SHIFT_DEPTH]};
            2'b01  : data_buffer_next = data_i;
            2'b10  : data_buffer_next = INPUT_DEPTH'(0);
            2'b11  : data_buffer_next = INPUT_DEPTH'(0);
            default: data_buffer_next = INPUT_DEPTH'(0);
        endcase
    end
    always_ff @(posedge clk) begin
        if (buffer_trigger) begin
            data_buffer_current <= data_buffer_next;
        end
    end
    assign data_o = data_buffer_current[SHIFT_DEPTH-1:0];

//* Empty Tracking
    reg    [INPUT_DEPTH-1:0] data_invalid_vec_current;
    logic  [INPUT_DEPTH-1:0] data_invalid_vec_next;
    wire               [1:0] data_invalid_vec_next_condition;
    assign                   data_invalid_vec_next_condition[0] = we_en_i;
    assign                   data_invalid_vec_next_condition[1] = clear_en_i || sync_rst;
    always_comb begin : data_invalid_vec_nextMux
        case (data_invalid_vec_next_condition)
            2'b00  : data_invalid_vec_next = {SHIFT_DEPTH'(0), data_invalid_vec_current[INPUT_DEPTH-1:SHIFT_DEPTH]};
            2'b01  : data_invalid_vec_next = INPUT_DEPTH'(0);
            2'b10  : data_invalid_vec_next = ~INPUT_DEPTH'(0);
            2'b11  : data_invalid_vec_next = ~INPUT_DEPTH'(0);
            default: data_invalid_vec_next = ~INPUT_DEPTH'(0);
        endcase
    end
    always_ff @(posedge clk) begin
        if (buffer_trigger) begin
            data_invalid_vec_current <= data_invalid_vec_next;
        end
    end
    assign empty_o = &data_invalid_vec_current[SHIFT_DEPTH-1:0];

endmodule : output_bit_shifter
