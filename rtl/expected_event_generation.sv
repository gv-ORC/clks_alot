
/*
Reacts instantly to incoming events.
Uses incoming events to calculate drifts.
Hold last Limit to check for the late-half of the drift window.
Detects and Forwards Drift Events
*/

    wire pin_came_late_check = more_than_rate && less_than_upper_bound;
    wire pin_came_early_check = less_than_rate && more_than_lower_bound;

    assign drift_detected_o = pin_came_late_check || pin_came_early_check;
    assign drift_direction_o = pin_came_late_check
                             ? clks_alot_p::PIN_CAME_LATE
                             : clks_alot_p::PIN_CAME_EARLY;
    assign drift_amount_o = pin_came_late_check
                          ? (rate_accumulator_i - active_rate_i)
                          ? (active_rate_i - rate_accumulator_i);
