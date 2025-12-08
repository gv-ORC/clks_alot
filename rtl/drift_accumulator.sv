module drift_accumulator (
    input                       common_p::clk_dom_s sys_dom_i,

    input                                           accumulator_en_i,

    input                                           pos_drift_detected_i,
    input                                           neg_drift_detected_i,

    input  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] max_drift_i,
    output                                          drift_acc_overflow_o,
    output                                          inverse_drift_violation_o,

    input                                           any_valid_edge_i

    output                                          pos_drift_ready_o,
    output                                          neg_drift_ready_o,
    input                                           drift_accepted_i
);

// Clock Configuration

// Accumulator

// Current Drift Direction

// Edges Since Last Drift

// Drift Application Lockout

endmodule : drift_accumulator
