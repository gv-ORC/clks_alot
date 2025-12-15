module sir_clks_alot (
    input                 common_p::clk_dom_s sys_dom_i,


    input        clks_alot_p::recovery_pins_s io_clk_i, // Already sync'd data pair

    //? Unpausable Output
    output         clks_alot_p::clock_state_s unpausable_expected_clk_state_o,
    output         clks_alot_p::clock_state_s unpausable_preemptive_clk_state_o,

    //? Pausable Output
    // Pauses maintain clock phasing when enabling and disabling
    // Pauses enable & disable when clock polarity matches
    input                                     pause_en_i,
    input                                     pause_polarity_i,
    output         clks_alot_p::clock_state_s pausable_expected_clk_state_o,
    output         clks_alot_p::clock_state_s pausable_preemptive_clk_state_o,
    output                                    pause_start_violation_o,
    output                                    pause_stop_violation_o
);

// NOTE: Inputs must be pre-synchronized

// Active Status
    reg  active_current;
    wire active_next = ~sync_rst && generation_en_i;
    wire active_trigger = sync_rst
                       || (clk_en && ~active_current && generation_en_i)
                       || (clk_en && active_current && ~(clock_state_current ^ starting_polarity_i));
    always_ff @(posedge clk) begin
        if (active_trigger) begin
            active_current <= active_next;
        end
    end

    reg  busy_delay_current;
    wire busy_delay_next = ~sync_rst && active_current && ~generation_en_i;
    wire busy_delay_trigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (busy_delay_trigger) begin
            busy_delay_current <= busy_delay_next;
        end
    end

    assign busy_o = active_current || busy_delay_current;

// Recovery
    wire                            primary_clk;
    clks_alot_p::recovered_events_s recovered_events;

    recovery recovery (
        .sys_dom_i                 (),
        .recovery_en_i             (),
        .clear_state_i             (),
        .source_select_i           (),
        .recovery_mode_i           (),
        .io_clk_i                  (),
        .bandpass_upper_bound_i    (),
        .bandpass_lower_bound_i    (),
        .bandpass_overshoot_o      (),
        .bandpass_undershoot_o     (),
        .drift_polarity_en_i       (),
        .drift_polarity_i          (),
        .drift_window_i            (),
        .positive_drift_violation_o(),
        .negative_drift_violation_o(),
        .clock_encoded_data_en_i   (),
        .rounding_polarity_i       (),
        .growth_rate_i             (),
        .decay_rate_i              (),
        .saturation_limit_i        (),
        .plateau_limit_i           (),
        .recovered_clk             (),
        .recovered_events_o        (),
        .fully_locked_in_o         (),
        .high_locked_in_o          (),
        .high_rate_changed_o       (),
        .high_rate_o               (),
        .low_locked_in_o           (),
        .low_rate_changed_o        (),
        .low_rate_o                ()
    );

// Generation


endmodule : sir_clks_alot
