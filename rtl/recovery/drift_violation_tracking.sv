module drift_violation_tracking (
    input                           common_p::clk_dom_s sys_dom_i,

    input                                               recovery_en_i,
    input                                               clear_state_i,

    input  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] growth_rate_i,
    input  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] decay_rate_i,
    input  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] saturation_limit_i,
    input  [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] violation_trigger_limit_i,

    input               clks_alot_p::recovered_events_s io_events_i,

    input                                               high_positive_drift_violation_i,
    input                                               high_negative_drift_violation_i,
    input                                               low_positive_drift_violation_i,
    input                                               low_negative_drift_violation_i,

    output                                              excessive_drift_violation_o
);

    // ToDo: Check if this needs to be synchronized via pipeline buffers or not.
    wire event_check = io_events_i.any_valid_edge;

    wire drift_detected = high_positive_drift_violation_i
                       || high_negative_drift_violation_i
                       || low_positive_drift_violation_i
                       || low_negative_drift_violation_i;

    wire [(clks_alot_p::VIOLATION_COUNTER_WIDTH)-1:0] null_plateau_limit = clks_alot_p::VIOLATION_COUNTER_WIDTH'(0);

    decaying_saturation_counter #(
        .BIT_WIDTH(clks_alot_p::VIOLATION_COUNTER_WIDTH)
    ) counter (
        .clk_dom_i         (sys_dom_i),
        .counter_en_i      (event_check),
        .decay_en_i        (~drift_detected),
        .clear_en_i        (clear_state_i),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_en_i      (1'b0),
        .plateau_limit_i   (violation_trigger_limit_i),
        .plateaued_o       (excessive_drift_violation_o),
        .count_o           () // Not Used
    );

endmodule : drift_violation_tracking




