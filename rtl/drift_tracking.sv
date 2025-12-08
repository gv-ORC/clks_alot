/**
 *  Module: drift_tracking
 *
 *  About: 
 *
 *  Ports:
 *
**/
module drift_tracking (

);

/*
// 1. Too many missing edges results in a pause (configurable amount of minimally required missing edges) - This will be in another module
// 2. Drifting too frequently (configurable minimal avg), throw a "non-even multiple" violation
3. Drift Accumulator overflow will result in a "non-even multiple" violation (this can be used to track #2)
4. Apply drift accumulator as applicable, with a configurable minimum number of edges between accumulator application
*/

// Drift Approximation - Drift Expected Clock in order to anticipate drifts during missing edges


// Drift Accumulator - Drift the preemptive clock to match any difting of the expected clock
drift_accumulator drift_accumulator (
    .sys_dom_i                (),
    .accumulator_en_i         (),
    .pos_drift_detected_i     (),
    .neg_drift_detected_i     (),
    .max_drift_i              (),
    .drift_acc_overflow_o     (),
    .inverse_drift_violation_o(),
    .any_valid_edge_i         (),
    .pos_drift_ready_o        (),
    .neg_drift_ready_o        (),
    .drift_accepted_i         ()
);






endmodule : drift_tracking
