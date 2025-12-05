module sense_filtering (
    input     clks_alot_p::half_rate_limits_s half_rate_limits_i,

    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] current_rate_counter_i,
    input                                     sense_event_i,

    output                                    filtered_event_o,
    output                                    over_frequency_violation_o,
    output                                    under_frequency_violation_o
);

// Limit Checks
    wire   ignore_over_check = current_rate_counter_i >= half_rate_limits_i.maximum_band_minus_one;
    wire   ignore_under_check = current_rate_counter_i <= half_rate_limits_i.minimum_band_minus_one;
    assign over_frequency_violation_o = (current_rate_counter_i >= half_rate_limits_i.maximum_violation_minus_one)
                                     && ~ignore_over_check;
    assign under_frequency_violation_o = (current_rate_counter_i <= half_rate_limits_i.minimum_violation_minus_one);
                                      && ~ignore_over_check;

// Sense Filter
    wire   ignore_check = ignore_over_check || ignore_under_check;
    assign filtered_event_o = sense_event_i && ~ignore_check;

endmodule : sense_filtering
