module pause_recovery (
    input                    common_p::clk_dom_s sys_dom_i,
    
    input                                      recovery_en_i,
    input       clks_alot_p::recovery_conf_s recovery_config_i,

    input      clks_alot_p::recovered_events_s recovered_events_i,
    input   [(clks_alot_p::COUNTER_WIDTH)-1:0] current_rate_i,

    output         clks_alot_p::pause_status_s pause_status_o
);



endmodule : pause_recovery
