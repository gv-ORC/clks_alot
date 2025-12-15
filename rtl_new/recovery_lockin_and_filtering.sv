module recovery_lockin_and_filtering (
// Polarity
    // If 1: Only allow events from a single edge
    // If 0: Accept events from both Rising and Falling edges
    input                                          event_polarity_en_i,
    // If 1: Only accept Rising Edges
    // If 0: Only accept Falling Edges
    input                                          event_polarity_i,
    input          clks_alot_p::recovered_events_s io_events_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] pending_rate_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] validated_rate_i,

// Bandpass
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_upper_bound_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] bandpass_lower_bound_i,
    output                                         bandpass_overshoot_o,
    output                                         bandpass_undershoot_o,

// Drift
    // If 1: Only allow drift in 1 direction
    // If 0: Allow drift in both directions
    input                                          drift_polarity_en_i,
    // If 1: Allow positive drift only
    // If 0: Allow negative drift only
    input                                          drift_polarity_i,
    input  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] drift_window_i,
    output                                         positive_drift_violation_o,
    output                                         negative_drift_violation_o,

// Halving
    input                                          clock_encoded_data_en_i,

// Lockin Feedback
    input                                          rate_locked_in_i,

    output                                         primary_event_o
);

// Polarity Filtering
    logic        polarity_filtered_event;
    wire   [1:0] polarity_filter_condition;
    assign       polarity_filter_condition[0] = event_polarity_en_i && event_polarity_i;
    assign       polarity_filter_condition[1] = event_polarity_en_i;
    always_comb begin : polarity_filter_mux
        case (primary_event_o_condition)
            2'b00  : polarity_filtered_event = io_events_i.any_valid_edge; // Either Edge
            2'b01  : polarity_filtered_event = io_events_i.any_valid_edge; // Either Edge
            2'b10  : polarity_filtered_event = io_events_i.falling_edge;   // Falling Edge Only
            2'b11  : polarity_filtered_event = io_events_i.rising_edge;    // Rising Edge Only
            default: polarity_filtered_event = 1'b0;
        endcase
    end

// Bandpass Filtering
    assign bandpass_overshoot_o = pending_rate > bandpass_upper_bound_i;
    assign bandpass_undershoot_o = pending_rate < bandpass_lower_bound_i;

    wire   badpass_fail = bandpass_overshoot_o || bandpass_undershoot_o;

// Drift Validation
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] upper_drift_bound = (drift_polarity_en_i && ~drift_polarity_i)
                                                                     ? validated_rate_i
                                                                     : (validated_rate_i + drift_window_i);
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] lower_drift_bound = (drift_polarity_en_i && drift_polarity_i)
                                                                     ? validated_rate_i
                                                                     : (validated_rate_i - drift_window_i);

    assign positive_drift_violation_o = pending_rate_i > upper_drift_bound;
    assign negative_drift_violation_o = pending_rate_i < lower_drift_bound;
    wire   drift_violation = positive_drift_violation_o || negative_drift_violation_o;

// Halving Detection
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] half_of_validated_rate = clks_alot_p::RATE_COUNTER_WIDTH'(validated_rate_i[(clks_alot_p::RATE_COUNTER_WIDTH)-1:1]);
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] halving_upper_bound = (drift_polarity_en_i && ~drift_polarity_i)
                                                                     ? half_of_validated_rate
                                                                     : (half_of_validated_rate + drift_window_i);
    wire                                         less_than_half_check = pending_rate_i <= halving_upper_bound;
    
    wire                                         halving_check = (pending_rate_i >= less_than_half_check) && clock_encoded_data_en_i;

// Primary Event Assignment
    assign  primary_event_o = rate_locked_in_i
                            ? (polarity_filtered_event && ~badpass_fail && (~drift_violation || halving_check))
                            : (polarity_filtered_event && ~badpass_fail);

endmodule : recovery_lockin_and_filtering
