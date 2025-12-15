module drift_accumulator (
    input                       common_p::clk_dom_s sys_dom_i,

    input                                           accumulator_en_i,
    input                                           clear_state_i,

    input                                           drift_detected_i,
    input            clks_alot_p::drift_direction_e drift_direction_i,

    input  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] max_drift_i,
    output                                          drift_acc_overflow_o,
    output                                          inverse_drift_violation_o,

    input  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] minimum_drift_lockout_duration_i,
    input                                           any_valid_edge_i,

    output                                          drift_req_o,
    input                                           drift_res_i,
    output           clks_alot_p::drift_direction_e drift_direction_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Drift Active
    reg  active_current;
    wire active_next = ~sync_rst && accumulator_en_i && ~clear_state_i;
    wire active_trigger = sync_rst
                       || (clk_en && drift_detected_i && accumulator_en_i)
                       || (clk_en && active_current && clear_state_i);
    always_ff @(posedge clk) begin
        if (active_trigger) begin
            active_current <= active_next;
        end
    end

    wire drift_accepted = drift_req_o && drift_res_i;

// Accumulator
    reg  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] drift_accumulator_current;
    wire [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] drift_accumulator_next;
    wire                                    [1:0] drift_accumulator_next_condition;
    assign                                        drift_accumulator_next_condition[0] = drift_ready && drift_res_i && ~drift_detected_i;
    assign                                        drift_accumulator_next_condition[1] = sync_rst;
    always_comb begin : drift_accumulator_nextMux
        case (drift_accumulator_next_condition)
            2'b00  : drift_accumulator_next = drift_accumulator_current + clks_alot_p::DRIFT_COUNTER_WIDTH'(1);
            2'b01  : drift_accumulator_next = drift_accumulator_current - clks_alot_p::DRIFT_COUNTER_WIDTH'(1);
            2'b10  : drift_accumulator_next = clks_alot_p::DRIFT_COUNTER_WIDTH'(0);
            2'b11  : drift_accumulator_next = clks_alot_p::DRIFT_COUNTER_WIDTH'(0);
            default: drift_accumulator_next = clks_alot_p::DRIFT_COUNTER_WIDTH'(0);
        endcase
    end
    wire drift_accumulator_trigger = sync_rst
                                  || (clk_en && accumulator_en_i && drift_detected_i && ~drift_accepted)
                                  || (clk_en && accumulator_en_i && drift_accepted && ~drift_detected_i)
                                  || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (drift_accumulator_trigger) begin
            drift_accumulator_current <= drift_accumulator_next;
        end
    end

// Current Drift Direction
    clks_alot_p::drift_direction_e direction_current;
    clks_alot_p::drift_direction_e direction_next;
    wire                           direction_trigger = sync_rst
                                                    || (clk_en && accumulator_en_i && drift_detected_i);
    always_ff @(posedge clk) begin
        if (direction_trigger) begin
            direction_current <= drift_direction_i;
        end
    end

// Edges Since Last Drift
    reg  [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] lockout_duration_current;
    wire [(clks_alot_p::DRIFT_COUNTER_WIDTH)-1:0] lockout_duration_next = (sync_rst || drift_accepted || clear_state_i)
                                                                        ? clks_alot_p::DRIFT_COUNTER_WIDTH'(0)
                                                                        : (lockout_duration_current + clks_alot_p::DRIFT_COUNTER_WIDTH'(1));
    wire                                          lockout_duration_trigger = sync_rst
                                                                          || (clk_en && any_valid_edge_i)
                                                                          || (clk_en && drift_accepted)
                                                                          || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (lockout_duration_trigger) begin
            lockout_duration_current <= lockout_duration_next;
        end
    end

// Output Assignments
    assign drift_acc_overflow_o = drift_accumulator_current > max_drift_i;
    assign inverse_drift_violation_o = ((direction_current == clks_alot_p::PIN_CAME_LATE) && drift_detected_i && (drift_direction_i == clks_alot_p::PIN_CAME_EARLY) && active_current)
                                    || ((direction_current == clks_alot_p::PIN_CAME_EARLY) && drift_detected_i && (drift_direction_i == clks_alot_p::PIN_CAME_LATE) && active_current);

    assign drift_req_o = (drift_accumulator_current != clks_alot_p::DRIFT_COUNTER_WIDTH'(0)) && (lockout_duration_current >= minimum_drift_lockout_duration_i);
    assign drift_direction_o = direction_current;

endmodule : drift_accumulator
