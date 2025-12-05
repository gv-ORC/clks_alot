module rate_recovery (
    input                  common_p::clk_dom_s sys_dom_i,
    
    input                                      recovery_en_i,
    input         clks_alot_p::recovery_conf_s recovery_config_i,

    input      clks_alot_p::recovered_events_s recovered_events_i,

    output  [(clks_alot_p::COUNTER_WIDTH)-1:0] current_rate_o,
    output clks_alot_p::recovered_half_rates_s recovered_half_rates_o
);

// Clock Config
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// High/50-50 Rate Counter
    half_rate_recovery high_rate_recovery (
        .sys_dom_i                  (),
        .recovery_en_i              (),
        .polarity_en_i              (),
        .polarity_i                 (),
        .primary_clk_i              (),
        .clear_state_i              (),
        .half_rate_limits_i         (),
        .sense_event_i              (),
        .current_rate_o             (),
        .over_frequency_violation_o (),
        .under_frequency_violation_o()
    );

// Low Rate Counter
    half_rate_recovery low_rate_recovery (
        .sys_dom_i                  (),
        .recovery_en_i              (),
        .polarity_en_i              (),
        .polarity_i                 (),
        .primary_clk_i              (),
        .clear_state_i              (),
        .half_rate_limits_i         (),
        .sense_event_i              (),
        .current_rate_o             (),
        .over_frequency_violation_o (),
        .under_frequency_violation_o()
    );

endmodule : rate_recovery
