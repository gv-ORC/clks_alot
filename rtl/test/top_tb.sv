// `include "hs_macro.sv"
module top_tb (
    input clk,
    input clk_en,
    input sync_rst,

    output        pcap_valid,
    output        pcap_last,
    output [31:0] pcap_data,
    output  [1:0] pcap_length_lower,

    output ERROR
);
/*

*/
//? Cycle Counter
    //                                                                   //
    //* Counter
        reg  [31:0] CycleCount;
        wire [31:0] NextCycleCount = sync_rst ? 32'd0 : (CycleCount + 1);
        wire        CycleLimitReached = CycleCount == CYCLELIMIT;
        wire CycleCountTrigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (CycleCountTrigger) begin
                CycleCount <= NextCycleCount;
            end
        end
    //                                                                   //
//?

//                                                                   //
//! Start Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //	

    common_p::clk_dom_s                           sys_dom_i;
    assign sys_dom_i.clk = clk;
    assign sys_dom_i.clk_en = clk_en;
    assign sys_dom_i.sync_rst = sync_rst;
 
    wire                                         enable_i = CycleCount >= 32'd32;
    wire                                         recover_i = 1'b1;
    wire                                         clear_state_i = CycleCount == 32'd16;
    wire                                         init_i = CycleCount == 32'd24;
    // ToDo: Test variations of this
    wire                                         starting_polarity_i = 1'b0;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_high_rate_i = clks_alot_p::RATE_COUNTER_WIDTH'(5);
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_low_rate_i = clks_alot_p::RATE_COUNTER_WIDTH'(5);
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_full_rate_i = generation_high_rate_i + generation_low_rate_i;
    wire                                         source_select_i = 1'b0;
    // ToDo: Test variations of this
    clks_alot_p::mode_e                          recovery_mode_i = clks_alot_p::SINGLE_CONTINUOUS;
    clks_alot_p::recovery_pins_s                 io_clk_i;
    wire                                         high_rate_bandpass_overshoot_o;
    wire                                         high_rate_bandpass_undershoot_o;
    wire                                         low_rate_bandpass_overshoot_o;
    wire                                         low_rate_bandpass_undershoot_o;
    wire                                         high_rate_positive_drift_violation_o;
    wire                                         high_rate_negative_drift_violation_o;
    wire                                         low_rate_positive_drift_violation_o;
    wire                                         low_rate_negative_drift_violation_o;
    wire                                         excessive_drift_violation_o;
    wire                                         expected_delta_mismatch_violation_o;
    wire                                         preemptive_delta_mismatch_violation_o;
    clks_alot_p::clock_state_s                   recovered_clk_state_o;
    clks_alot_p::clock_state_s                   unpausable_expected_clk_state_o;
    clks_alot_p::clock_state_s                   unpausable_preemptive_clk_state_o;
    // ToDo: Test variations of this
    wire                                         pause_en_i = 1'b0;
    wire                                         pause_polarity_i = 1'b0;
    clks_alot_p::clock_state_s                   pausable_expected_clk_state_o;
    clks_alot_p::clock_state_s                   pausable_preemptive_clk_state_;

//! End Supporting Logic ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ //
//                                                                   //

//                                                                   //
//! Start Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//

    wire init_test_clks = CycleCount == 32'd7;
    wire test_clks_en = CycleCount >= 32'd12;

    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] pos_high_rate = clks_alot_p::RATE_COUNTER_WIDTH'(4);
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] pos_low_rate = clks_alot_p::RATE_COUNTER_WIDTH'(4);
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] neg_high_rate = clks_alot_p::RATE_COUNTER_WIDTH'(4);
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] neg_low_rate = clks_alot_p::RATE_COUNTER_WIDTH'(4);


    test_clk pos_test_clk (
        .sys_dom_i          (sys_dom_i),
        .init_i             (init_test_clks),
        .starting_polarity_i(1'b0),
        .generation_en_i    (test_clks_en),
        .high_rate_i        (pos_high_rate),
        .low_rate_i         (pos_low_rate),
        .clk_o              (io_clk_i.pos)
    );

    test_clk neg_test_clk (
        .sys_dom_i          (sys_dom_i),
        .init_i             (init_test_clks),
        .starting_polarity_i(1'b1),
        .generation_en_i    (test_clks_en),
        .high_rate_i        (neg_high_rate),
        .low_rate_i         (neg_low_rate),
        .clk_o              (io_clk_i.neg)
    );

    top top (
        .sys_dom_i                            (sys_dom_i),
        .enable_i                             (enable_i),
        .recover_i                            (recover_i),
        .clear_state_i                        (clear_state_i),
        .init_i                               (init_i),
        .starting_polarity_i                  (starting_polarity_i),
        .generation_high_rate_o               (generation_high_rate_o),
        .generation_low_rate_o                (generation_low_rate_o),
        .generation_full_rate_o               (generation_full_rate_o),
        .source_select_i                      (source_select_i),
        .recovery_mode_i                      (recovery_mode_i),
        .io_clk_i                             (io_clk_i),
        .high_rate_bandpass_overshoot_o       (high_rate_bandpass_overshoot_o),
        .high_rate_bandpass_undershoot_o      (high_rate_bandpass_undershoot_o),
        .low_rate_bandpass_overshoot_o        (low_rate_bandpass_overshoot_o),
        .low_rate_bandpass_undershoot_o       (low_rate_bandpass_undershoot_o),
        .high_rate_positive_drift_violation_o (high_rate_positive_drift_violation_o),
        .high_rate_negative_drift_violation_o (high_rate_negative_drift_violation_o),
        .low_rate_positive_drift_violation_o  (low_rate_positive_drift_violation_o),
        .low_rate_negative_drift_violation_o  (low_rate_negative_drift_violation_o),
        .excessive_drift_violation_o          (excessive_drift_violation_o),
        .expected_delta_mismatch_violation_o  (expected_delta_mismatch_violation_o),
        .preemptive_delta_mismatch_violation_o(preemptive_delta_mismatch_violation_o),
        .recovered_clk_state_o                (recovered_clk_state_o),
        .unpausable_expected_clk_state_o      (unpausable_expected_clk_state_o),
        .unpausable_preemptive_clk_state_o    (unpausable_preemptive_clk_state_o),
        .pause_en_i                           (pause_en_i),
        .pause_polarity_i                     (pause_polarity_i),
        .pausable_expected_clk_state_o        (pausable_expected_clk_state_o),
        .pausable_preemptive_clk_state_o      (pausable_preemptive_clk_state_o)
    );

//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//
//                                                                   //

endmodule : top_tb

