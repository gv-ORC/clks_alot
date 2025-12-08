module recovery (
    input                 common_p::clk_dom_s sys_dom_i,

    input                                     recovery_en_i,
    // Used for differential and quad-state signals to decide which input is used to determine the primary clock edges
    // 0: io_clk_i.neg edges are forwarded, with io_clk_i.pos used for verification
    // 1: io_clk_i.pos edges are forwarded, with io_clk_i.neg used for verification
    // Use for single-ended signals to decide which input is used as the clock signal
    // 0: io_clk_i.neg used
    // 1: io_clk_i.pos used
    input                                     source_select_i,
    input        clks_alot_p::recovery_conf_s recovery_config_i,
    output                                    busy_o,


    input                                     pause_polarity_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] minimum_pause_cycles_i,

    input        clks_alot_p::recovery_pins_s io_clk_i, // Already sync'd data pair

    output                                    edge_half_rate_minus_one_o,
    output        clks_alot_p::clock_states_s actual_clk_state_o
);

/*

Locked-in occurs when there has been at least 2 full clock cycles (4 half-rates have passed)

Manage Average drift rate and adjusting the half-rates accordingly,
Before recovery is locked-in, update half-rate immediately
After recovery is locked-in, update half-rate halfway through the next cycle

*/

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

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
        .recovery_en_i     (recovery_en_i),
        .source_select_i   (source_select_i),
        .recovery_mode_i   (recovery_config_i.mode),
        .io_clk_i          (io_clk_i),
        .primary_clk_o     (primary_clk),
        .recovered_events_o(recovered_events),
    );

// Rate Recovery
    rate_recovery rate_recovery (

    );

// Pause Recovery
    pause_recovery pause_recovery (

    ):

// Drift Averaging - Accounts for holding steady during external pause events (if different drift directions, throw violation)
    // This could be used to predict the next nudge


endmodule : recovery
