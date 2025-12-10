module lockin (
    input                 common_p::clk_dom_s sys_dom_i,

    input                                     lockin_en_i,
    input                                     clear_state_i,

    input      clks_alot_p::drift_direction_e active_drift_direction_i, // This should already have the active drift direction taken into account.
    input     clks_alot_p::half_rate_limits_s half_rate_limits_i,

    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rate_accumulator_i,
    input                                     filtered_event_i,
    input                                     polarity_filtered_event_i,
    input                                     active_rate_valid_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_rate_i,
    
    // These signals loop back to drive `active_drift_direction_i` after the first valid drift
    output                                    drift_detected_o,
    output     clks_alot_p::drift_direction_e drift_direction_o,
    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_amount_o,

    output                                    update_rate_o,
    output                                    clear_rate_o,
    output                                    locked_in_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Direction Selection
    wire full_drift_direction_en = half_rate_limits_i.full_drift_direction_en;

    wire using_pin_came_late = (active_drift_direction_i == clks_alot_p::PIN_CAME_LATE)
                            || full_drift_direction_en;
    wire using_pin_came_early = (active_drift_direction_i == clks_alot_p::PIN_CAME_EARLY)
                             || full_drift_direction_en;

// Half Rate Check
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_of_active_rate = clks_alot_p::RATE_COUNTER_WIDTH'(active_rate_i[(clks_alot_p::RATE_COUNTER_WIDTH)-1:1]);
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_upper_bound = using_pin_came_late
                                                             ? (half_of_active_rate + half_rate_limits_i.drift_window)
                                                             : half_of_active_rate; // Dont need to subtract since the half rate will be the upper bound
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_lower_bound = using_pin_came_early
                                                             ? (half_of_active_rate_i - half_rate_limits_i.drift_window)
                                                             : half_of_active_rate_i; // Dont need to add since the half rate will be the upper bound
    // Update active rate anytime this is true during a filtered event - signals we may not have the shortest bit duration
    wire less_than_half_upper_bound = rate_accumulator_i <= half_upper_bound;
    wire more_than_half_lower_bound = rate_accumulator_i >= half_lower_bound;
    wire rate_within_half_window = less_than_half_upper_bound && more_than_half_lower_bound;

// Drift Window Check
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] upper_bound = using_pin_came_late
                                                        ? (active_rate_i + half_rate_limits_i.drift_window)
                                                        : active_rate_i; // Dont need to subtract since the half rate will be the upper bound
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] lower_bound = using_pin_came_early
                                                        ? (active_rate_i - half_rate_limits_i.drift_window)
                                                        : active_rate_i; // Dont need to add since the half rate will be the upper bound
    
    wire less_than_upper_bound = rate_accumulator_i <= upper_bound;
    wire more_than_rate = rate_accumulator_i > active_rate_i;
    wire more_than_lower_bound = rate_accumulator_i >= lower_bound;
    wire less_than_rate = rate_accumulator_i < active_rate_i;
    
    wire rate_within_window = less_than_upper_bound && more_than_half_lower_bound;
    wire pin_came_late_check = more_than_rate && less_than_upper_bound;
    wire pin_came_early_check = less_than_rate && more_than_lower_bound;

    assign drift_detected_o = pin_came_late_check || pin_came_early_check;
    assign drift_direction_o = pin_came_late_check
                             ? clks_alot_p::PIN_CAME_LATE
                             : clks_alot_p::PIN_CAME_EARLY;
    assign drift_amount_o = pin_came_late_check
                          ? (rate_accumulator_i - active_rate_i)
                          ? (active_rate_i - rate_accumulator_i);

// Lockin Accumulator
    reg  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] lockin_accumulator_current;
    wire                                    lockin_saturation_check = lockin_accumulator_current == half_rate_limits_i.required_lockin_duration;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] lockin_accumulator_next = (sync_rst || ~rate_within_window || clear_state_i)
                                                                    ? clks_alot_p::RATE_COUNTER_WIDTH'(0)
                                                                    : (lockin_accumulator_current + clks_alot_p::RATE_COUNTER_WIDTH'(1));
    wire                                    lockin_accumulator_trigger = sync_rst 
                                                                      || (clk_en && polarity_filtered_event_i && lockin_en_i)
                                                                      || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (lockin_accumulator_trigger) begin
            lockin_accumulator_current <= lockin_accumulator_next;
        end
    end

// Locked In Status
    reg  locked_in_current;
    wire locked_in_next = ~sync_rst && lockin_saturation_check && rate_within_window && ~clear_state_i;
    wire locked_in_trigger = sync_rst
                          || (clk_en && lockin_saturation_check && lockin_en_i)
                          || (clk_en && polarity_filtered_event_i && lockin_en_i)
                          || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (locked_in_trigger) begin
            locked_in_current <= locked_in_next;
        end
    end
    assign locked_in_o = locked_in_current;

// Event Filtering
    assign update_rate_o = (polarity_filtered_event_i && active_rate_valid_i && rate_within_window)
                        || (polarity_filtered_event_i && ~active_rate_valid_i);
    assign clear_rate_o = filtered_event_i
                        || (polarity_filtered_event_i && active_rate_valid_i && rate_within_half_window);

endmodule : lockin
