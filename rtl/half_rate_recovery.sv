module half_rate_recovery (
    input                  common_p::clk_dom_s sys_dom_i,
    
    input                                      recovery_en_i,
    // When enabled:
    // `polarity` == 0: Only track high-level rates
    // `polarity` == 1: Only track low-level rates
    input                                      polarity_en_i,
    input                                      polarity_i,
    input                                      primary_clk_i,
    input                                      clear_state_i,
    input      clks_alot_p::half_rate_limits_s half_rate_limits_i,

    input                                      sense_event_i,

    output  [(clks_alot_p::COUNTER_WIDTH)-1:0] current_rate_o,
    output                                     over_frequency_violation_o,
    output                                     under_frequency_violation_o
);

// Clock Config
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Lock-In - Take the configured Min/Max half-rates and slowly narrow them down to what the active clock is currently at
    reg  [(clks_alot_p::COUNTER_WIDTH-1):0] rate_counter_current;
    wire                                    filtered_event;
    wire    clks_alot_p::half_rate_limits_s filtered_limits;

    //TODO: Complete this module
    lockin lockin (
        .sys_dom_i             (sys_dom_i),
        .recovery_en_i         (recovery_en_i),
        .half_rate_limits_i    (half_rate_limits_i),
        .current_rate_counter_i(rate_counter_current),
        .filtered_event_i      (filtered_event),
        .filtered_limits_o     (filtered_limits)
    );

// Sense Filtering - Only Allow `sense_event_i` to update when within the band max/min
    //TODO: Add polarity Filter
    sense_filtering sense_filtering (
        .half_rate_limits_i         (filtered_limits),
        .current_rate_counter_i     (rate_counter_current),
        .sense_event_i              (sense_event_i),
        .filtered_event_o           (filtered_event),
        .over_frequency_violation_o (over_frequency_violation_o),
        .under_frequency_violation_o(under_frequency_violation_o)
    );

// Rate Counter


endmodule : half_rate_recovery
