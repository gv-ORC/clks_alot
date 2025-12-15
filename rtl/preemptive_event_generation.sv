/*
Reacts to drift events - Allows drifts to offset the next limit during preemptive events. 
Uses active High Half-Rate and Low Half-Rate during event updates.
*/

/**
 *  Module: peemptive_event_generation
 *
 *  About: 
 *
 *  Ports:
 *
**/
module peemptive_event_generation (
    input                       common_p::clk_dom_s sys_dom_i,

    input                                           generation_en_i,

    input                                           init_generation_i,
    input   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] preemtive_depth_i,

    input                                           drift_req_i, // High/Low drift selection will be done inside the drift controller using `unpausable_clk_state_o.clk`
    output                                          drift_ack_o,
    input            clks_alot_p::drift_direction_e preemptive_drift_direction_i,
    input  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] drift_amount_i,

    input   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] generation_counter_i,
    input   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_high_rate_i,
    input   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_low_rate_i,

    output               clks_alot_p::clock_state_s unpausable_clk_state_o,
    output               clks_alot_p::clock_state_s pausable_clk_state_o

);



endmodule : peemptive_event_generation
