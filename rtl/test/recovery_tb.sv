`include "hs_macro.sv"
module kloch_random_test_tb (
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
    wire                                          recovery_en_i = CycleCount >= 32'd15;
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
    wire                                          clock_encoded_data_en_i = 1'b1;
    wire                                          rounding_polarity_i = 1'b0;
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] growth_rate_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'();
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] decay_rate_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'();
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] saturation_limit_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'();
    wire [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] plateau_limit_i = clks_alot_p::PRIORITIZE_COUNTER_WIDTH'();
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

//TODO: should drift violations still count as primary events?
//TODO: add saturation counter for drift violations, this could trigger an optional auto-reset

test_clk pos_test_clk (
    .sys_dom_i          (),
    .init_i             (),
    .starting_polarity_i(),
    .generation_en_i    (),
    .high_rate_i        (),
    .low_rate_i         (),
    .clk_o              (io_clk_i.pos),
);

test_clk neg_test_clk (
    .sys_dom_i          (),
    .init_i             (),
    .starting_polarity_i(),
    .generation_en_i    (),
    .high_rate_i        (),
    .low_rate_i         (),
    .clk_o              (io_clk_i.neg),
);

recovery recovery (
    .sys_dom_i                           (),
    .recovery_en_i                       (),
    .clear_state_i                       (),
    .source_select_i                     (),
    .recovery_mode_i                     (),
    .io_clk_i                            (),
    .bandpass_upper_bound_i              (),
    .bandpass_lower_bound_i              (),
    .high_rate_bandpass_overshoot_o      (),
    .high_rate_bandpass_undershoot_o     (),
    .low_rate_bandpass_overshoot_o       (),
    .low_rate_bandpass_undershoot_o      (),
    .drift_polarity_en_i                 (),
    .drift_polarity_i                    (),
    .drift_window_i                      (),
    .high_rate_positive_drift_violation_o(),
    .high_rate_negative_drift_violation_o(),
    .low_rate_positive_drift_violation_o (),
    .low_rate_negative_drift_violation_o (),
    .clock_encoded_data_en_i             (),
    .rounding_polarity_i                 (),
    .growth_rate_i                       (),
    .decay_rate_i                        (),
    .saturation_limit_i                  (),
    .plateau_limit_i                     (),
    .recovered_clk                       (),
    .recovered_events_o                  (),
    .fully_locked_in_o                   (),
    .high_locked_in_o                    (),
    .high_rate_changed_o                 (),
    .high_rate_o                         (),
    .low_locked_in_o                     (),
    .low_rate_changed_o                  (),
    .low_rate_o                          (),
);

//! End Module Tested ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~//
//                                                                   //

endmodule : kloch_random_test_tb

