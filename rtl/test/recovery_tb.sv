// `include "hs_macro.sv"
module recovery_tb (
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
    wire                                          recovery_en_i = CycleCount >= 32'd64;
    wire                                          clear_state_i = 1'b0;
    wire                                          source_select_i = 1'b0;
    clks_alot_p::mode_e                           recovery_mode_i;
    assign recovery_mode_i = clks_alot_p::SINGLE_CONTINUOUS;
    clks_alot_p::recovery_pins_s                  io_clk_i;
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_upper_bound_i = clks_alot_p::RATE_COUNTER_WIDTH'(10);
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_lower_bound_i = clks_alot_p::RATE_COUNTER_WIDTH'(4);
    wire                                          high_rate_bandpass_overshoot_o;
    wire                                          high_rate_bandpass_undershoot_o;
    wire                                          low_rate_bandpass_overshoot_o;
    wire                                          low_rate_bandpass_undershoot_o;
    wire                                          drift_polarity_en_i = 1'b0;
    wire                                          drift_polarity_i = 1'b0;
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_window_i = clks_alot_p::RATE_COUNTER_WIDTH'(1);
    wire                                          high_rate_positive_drift_violation_o;
    wire                                          high_rate_negative_drift_violation_o;
    wire                                          low_rate_positive_drift_violation_o;
    wire                                          low_rate_negative_drift_violation_o;
    wire                                          excessive_drift_violation_o;
    wire                                          clock_encoded_data_en_i = 1'b1;
    wire                                          rounding_polarity_i = 1'b0;

    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_growth_rate_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(10);
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_decay_rate_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(5);
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_saturation_limit_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(80);
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] prioritization_plateau_limit_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'(40);

    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_growth_rate_i = clks_alot_p::VIOLATION_COUNTER_WIDTH'(8);
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_decay_rate_i = clks_alot_p::VIOLATION_COUNTER_WIDTH'(1);
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_saturation_limit_i = clks_alot_p::VIOLATION_COUNTER_WIDTH'(32);
    wire  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_trigger_limit_i = clks_alot_p::VIOLATION_COUNTER_WIDTH'(24);

    wire                                          recovered_clk_o;
    clks_alot_p::recovered_events_s               recovered_events_o;
    wire                                          fully_locked_in_o;
    wire                                          high_locked_in_o;
    wire                                          high_rate_changed_o;
    wire  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_rate_o;
    wire                                          low_locked_in_o;
    wire                                          low_rate_changed_o;
    logic [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_rate_o;

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

    recovery recovery (
        .sys_dom_i                           (sys_dom_i),
        .recovery_en_i                       (recovery_en_i),
        .clear_state_i                       (clear_state_i),
        .source_select_i                     (source_select_i),
        .recovery_mode_i                     (recovery_mode_i),
        .io_clk_i                            (io_clk_i),
        .bandpass_upper_bound_i              (bandpass_upper_bound_i),
        .bandpass_lower_bound_i              (bandpass_lower_bound_i),
        .high_rate_bandpass_overshoot_o      (high_rate_bandpass_overshoot_o),
        .high_rate_bandpass_undershoot_o     (high_rate_bandpass_undershoot_o),
        .low_rate_bandpass_overshoot_o       (low_rate_bandpass_overshoot_o),
        .low_rate_bandpass_undershoot_o      (low_rate_bandpass_undershoot_o),
        .drift_polarity_en_i                 (drift_polarity_en_i),
        .drift_polarity_i                    (drift_polarity_i),
        .drift_window_i                      (drift_window_i),
        .high_rate_positive_drift_violation_o(high_rate_positive_drift_violation_o),
        .high_rate_negative_drift_violation_o(high_rate_negative_drift_violation_o),
        .low_rate_positive_drift_violation_o (low_rate_positive_drift_violation_o),
        .low_rate_negative_drift_violation_o (low_rate_negative_drift_violation_o),
        .excessive_drift_violation_o         (excessive_drift_violation_o),
        .clock_encoded_data_en_i             (clock_encoded_data_en_i),
        .rounding_polarity_i                 (rounding_polarity_i),
        .prioritization_growth_rate_i        (prioritization_growth_rate_i),
        .prioritization_decay_rate_i         (prioritization_decay_rate_i),
        .prioritization_saturation_limit_i   (prioritization_saturation_limit_i),
        .prioritization_plateau_limit_i      (prioritization_plateau_limit_i),
        .violation_growth_rate_i             (violation_growth_rate_i),
        .violation_decay_rate_i              (violation_decay_rate_i),
        .violation_saturation_limit_i        (violation_saturation_limit_i),
        .violation_trigger_limit_i           (violation_trigger_limit_i),
        .recovered_clk                       (recovered_clk),
        .recovered_events_o                  (recovered_events_o),
        .fully_locked_in_o                   (fully_locked_in_o),
        .high_locked_in_o                    (high_locked_in_o),
        .high_rate_changed_o                 (high_rate_changed_o),
        .high_rate_o                         (high_rate_o),
        .low_locked_in_o                     (low_locked_in_o),
        .low_rate_changed_o                  (low_rate_changed_o),
        .low_rate_o                          (low_rate_o)
    );

//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//
//                                                                   //

endmodule : recovery_tb

