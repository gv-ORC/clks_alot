module event_filtering (
    input     clks_alot_p::half_rate_limits_s half_rate_limits_i,

    // When enabled:
    // `polarity` == 0: Only track high-level rates
    // `polarity` == 1: Only track low-level rates
    input                                     polarity_en_i,
    input                                     polarity_i,
    input                                     primary_clk_i,

    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] current_rate_counter_i,
    input                                     event_i,

    output                                    ignore_filtered_event_o,
    output                                    polarity_filtered_event_o,
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
    assign ignore_filtered_event_o = event_i && ~ignore_check;
    // TODO: This may be a critical path....
    assign polarity_filtered_event_o = (event_i && ~ignore_check && polarity_en_i && polarity_i && ~primary_clk_i)
                                    || (event_i && ~ignore_check && polarity_en_i && ~polarity_i && primary_clk_i)
                                    || (event_i && ~ignore_check && ~polarity_en_i);

endmodule : event_filtering
