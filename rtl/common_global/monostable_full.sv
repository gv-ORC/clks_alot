/**
 *  Module: monostable_full
 *
 *  About: 
 *
 *  Ports:
 *
**/
module monostable_full #(
    parameter bit BUFFERED = 1'b0
)(
    input  sys_structs::clk_dom_sain clk_dom_s_i,

    input                          monostable_en_i,

    input                          sense_i,
    
    output                         prev_o,
    output                         posedge_mono_o,
    output                         negedge_mono_o,
    output                         bothedge_mono_o
);

// Clock Configuration
    wire clk = clk_dom_s_i.clk;
    wire clk_en = clk_dom_s_i.clk_en;
    wire sync_rst = clk_dom_s_i.sync_rst;

// Previous State    
    reg  sense_prev_current;
    wire sense_prev_next = ~sync_rst && sense_i && monostable_en_i;
    wire sense_prev_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (sense_prev_trigger) begin
            sense_prev_current <= sense_prev_next;
        end
    end

// Optional Output Buffer
    generate
        if (BUFFERED) begin
            wire       posedge_check = ~sense_prev_current && sense_i && monostable_en_i;
            wire       negedge_check = sense_prev_current && ~sense_i && monostable_en_i;
            wire       bothedge_check = (sense_prev_current ^ sense_i) && monostable_en_i;

            reg  [3:0] output_buffer_current;
            wire [3:0] output_buffer_next = sync_rst
                                          ? 4'd0
                                          : {sense_prev_current, posedge_check, negedge_check, bothedge_check};
            wire        output_buffer_trigger = sync_rst || clk_en;
            always_ff @(posedge clk) begin
                if (output_buffer_trigger) begin
                    output_buffer_current <= output_buffer_next;
                end
            end

            assign prev_o = output_buffer_current[3];
            assign posedge_mono_o = output_buffer_current[2];
            assign negedge_mono_o = output_buffer_current[1];
            assign bothedge_mono_o = output_buffer_current[0];
        end
        else begin
            assign prev_o = sense_prev_current;
            assign posedge_mono_o = ~sense_prev_current && sense_i && monostable_en_i;
            assign negedge_mono_o = sense_prev_current && ~sense_i && monostable_en_i;
            assign bothedge_mono_o = posedge_mono_o || negedge_mono_o;
        end
    endgenerate

endmodule : monostable_full
