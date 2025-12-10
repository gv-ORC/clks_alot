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

// Event Recovery
    wire                            primary_clk;
    clks_alot_p::recovered_events_s recovered_events;

    event_recovery event_recovery (
        .sys_dom_i         (sys_dom_i),
        .recovery_en_i     (),
        .source_select_i   (),
        .recovery_mode_i   (),
        .io_clk_i          (io_clk_i),
        .primary_clk_o     (primary_clk),
        .recovered_events_o(recovered_events),
    );
    
// Rate Recovery
    rate_recovery rate_recovery (
    
    );

// Clocks & Event Generation (Needs to provide event feedback)


endmodule : sir_clks_alot
