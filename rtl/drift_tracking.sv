/**
 *  Module: drift_tracking
 *
 *  About: 
 *
 *  Ports:
 *
**/
module drift_tracking (
    input                       common_p::clk_dom_s sys_dom_i,

    input                                           accumulator_en_i,
    input                                           clear_state_i,

    input                                           drift_detected_i,
    input           clks_alot_p::half_rate_limits_s drift_limits_i, // TODO: update with `fixed_drift_direction_en`
    input            clks_alot_p::drift_direction_e drift_direction_i,

    input  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] max_drift_i,
    output                                          drift_acc_overflow_o,
    output                                          inverse_drift_violation_o,

    input  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] minimum_drift_lockout_duration_i,
    input                                           any_valid_edge_i,

    output                                          expected_drift_req_o,
    input                                           expected_drift_res_i,
    output           clks_alot_p::drift_direction_e expected_drift_direction_o,

    output                                          preemptive_drift_req_o,
    input                                           preemptive_drift_res_i,
    output           clks_alot_p::drift_direction_e preemptive_drift_direction_o
);

/*
// 1. Too many missing edges results in a pause (configurable amount of minimally required missing edges) - This will be in another module
// 2. Drifting too frequently (configurable minimal avg), throw a "non-even multiple" violation
3. Drift Accumulator overflow will result in a "non-even multiple" violation (this can be used to track #2)
4. Apply drift accumulator as applicable, with a configurable minimum number of edges between accumulator application
*/

// Drift Approximation - Drift Expected Clock in order to anticipate drifts during missing edges


// Drift Accumulator - Drift the preemptive clock to match any difting of the expected clock
//TODO: Refactor this to hold a drift only long enough for the next respective edge, 
//TODO: Have some sort of Build-and-Decay system to check for drifts happening too often
//TODO: ... Have the following 3 configurations; Growth
//TODO: 1. Growth Rate - How much is added to a saturation counter during a drift
//TODO: 2. Decay Rate - How much is subtracted every event a drift does not occur
//TODO: 3. Ceiling - The saturation point of the counter, if this is reached - throw a violation
    drift_accumulator drift_accumulator (
        .sys_dom_i                       (),
        .accumulator_en_i                (),
        .clear_state_i                   (),
        .drift_detected_i                (),
        .drift_direction_i               (),
        .max_drift_i                     (),
        .drift_acc_overflow_o            (),
        .inverse_drift_violation_o       (),
        .minimum_drift_lockout_duration_i(),
        .any_valid_edge_i                (),
        .drift_req_o                     (),
        .drift_res_i                     (),
        .drift_direction_o               ()
    );



endmodule : drift_tracking
