module recovery (
    input                   common_p::clk_dom sys_dom_i,

    input                                     recovery_en,
    input                               [2:0] recovery_mode_i, // Replace this with an enum
    output                                    busy_o,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] minimum_half_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] maximum_half_rate_minus_one_i,

    input                                     pause_en_i,
    input                                     pause_polarity_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] minimum_pause_cycles_i,

    input        clks_alot_p::recovery_pins_s clk_data_i, // Already sync'd data pair

    output                                    edge_half_rate_minus_one_o,
    output        clks_alot_p::clock_states_s actual_clk_state_o
);

/*
Types of Incoming Clocks: (recovery_mode_i)
1. Single Ended Continous Clock - w/o Pause
2. Single Ended Continous Clock - with Pause
3. Single Ended Data
4. Differential Pair Clock (LVDS) - w/o Pause
5. Differential Pair Clock (LVDS) - with Pause
6. Differential Pair Data (LVDS) - w/o Pause
7. Differential Pair Data (LVDS) - with Pause

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

// Edge Detection & Event Generation

// Cycle Counter

// Pause Detection

// Drift Averaging

// Half-Rate Averaging

endmodule : recovery
