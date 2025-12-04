module generation (
    input                   common_p::clk_dom sys_dom_i,

    //? Generation
    input                                     set_polarity_i,
    input                                     starting_polarity_i,

    input                                     generation_en_i, // When this goes low, clock will stop on the next starting_polarity
    output                                    busy_o,
    //! NOTE: expected_half_rate should be AT LEAST `preemptive_delay + sync_cycle_offset + 1` - Double check this
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] expected_half_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] expected_quarter_rate_minus_one_i,
    //! NOTE: Effective preemptive delay MUST be longer than `sync_cycle_offset` - By at least X????
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] preemptive_half_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] preemptive_quarter_rate_minus_one_i,
    // Pauses maintain clock phasing when enabling and disabling
    // Pauses enable & disable when clock polarity matches
    input                                     pause_en_i,
    input                                     pause_polarity_i,
    output                                    pause_start_violation_o,
    output                                    pause_stop_violation_o,

    //? Recovery - To accomodate for skew/drift
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] sync_cycle_offset_i,
    input         clks_alot_p::clock_states_s actual_clk_state_i,

    //? Generated Clocks
    output        clks_alot_p::clock_states_s expected_clk_state_o,
    output        clks_alot_p::clock_states_s preemptive_clk_state_o
);

/*
Based on estimates so far, minimum half-rate would be (preemptive_delay[5] + sync_cycle_offset_i[4] + 1) = 10... 
Resulting in:
> core clk - Max IO clk
   100 Mhz - 5 Mhz
   150 Mhz - 7.5 Mhz
   200 Mhz - 10 Mhz
   250 Mhz - 12.5 Mhz

TODO: Add more violation checks
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

// Cycle Counter
    reg    [(clks_alot_p::COUNTER_WIDTH)-1:0] cycle_count_current;

    wire                                      recovery_check = actual_clk_state_i.events.falling_edge || actual_clk_state_i.events.rising_edge;
    wire                                      expected_half_rate_elapsed = cycle_count_current == expected_half_rate_minus_one_i;
    wire                                      expected_quarter_rate_elapsed = cycle_count_current == expected_quarter_rate_minus_one_i;
    wire                                      preemptive_half_rate_elapsed = cycle_count_current == preemptive_half_rate_minus_one_i;
    wire                                      preemptive_quarter_rate_elapsed = cycle_count_current == preemptive_quarter_rate_minus_one_i;
    
    logic  [(clks_alot_p::COUNTER_WIDTH)-1:0] cycle_count_next;
    wire                                [1:0] cycle_count_next_condition;
    assign                                    cycle_count_next_condition[0] = recovery_check;
    assign                                    cycle_count_next_condition[1] = expected_half_rate_elapsed || sync_rst || busy_delay_current;
    always_comb begin : cycle_count_nextMux
        case (cycle_count_next_condition)
            2'b00  : cycle_count_next = cycle_count_current + clks_alot_p::COUNTER_WIDTH'(1);
            2'b01  : cycle_count_next = sync_cycle_offset_i;
            2'b10  : cycle_count_next = clks_alot_p::COUNTER_WIDTH'(0);
            2'b11  : cycle_count_next = clks_alot_p::COUNTER_WIDTH'(0);
            default: cycle_count_next = clks_alot_p::COUNTER_WIDTH'(0);
        endcase
    end
    wire cycle_count_trigger = sync_rst
                            || (clk_en && active_current)
                            || (clk_en && busy_delay_current);
    always_ff @(posedge clk) begin
        if (cycle_count_trigger) begin
            cycle_count_current <= cycle_count_next;
        end
    end

// Clock Control, Expected - Inherent 1 Cycle Delay to enforce phase-accurate pausing
    wire set_expected_clock_low = (set_polarity_i && ~starting_polarity_i)
                               || (busy_delay_current && ~starting_polarity_i)
                               || actual_clk_state_i.events.falling_edge;
    wire set_expected_clock_high = (set_polarity_i && ~starting_polarity_i)
                                || (busy_delay_current && starting_polarity_i)
                                || actual_clk_state_i.events.rising_edge;

    clock_state expected_clock_state (
        .sys_dom_i             (sys_dom_i),
        .set_clock_low_i       (set_expected_clock_low),
        .set_clock_high_i      (set_expected_clock_high),
        .clock_active_i        (active_current),
        .clear_state_i         (busy_delay_current),
        .half_rate_elapsed_i   (expected_half_rate_elapsed),
        .quarter_rate_elapsed_i(expected_quarter_rate_elapsed),
        .pause_en_i            (pause_en_i),
        .pause_polarity_i      (pause_polarity_i),
        .state_o               (expected_clk_state_o)
    );

    wire expected_pause_active_pulse;

    monostable_full #(
        .BUFFERED(1'b0)
    ) expected_pause_monostable_gen (
        .clk_dom_i      (sys_dom_i),
        .monostable_en_i(1'b1),
        .sense_i        (expected_clk_state_o.pause_active),
        .prev_o         (), // Not Used
        .posedge_mono_o (expected_pause_active_pulse),
        .negedge_mono_o (), // Not Used
        .bothedge_mono_o()  // Not Used
    );

// Clock Control, Preemptive - Inherent 1 Cycle Delay to enforce phase-accurate pausing
    wire set_preemptive_clock_low = (set_polarity_i && ~starting_polarity_i)
                                 || (busy_delay_current && ~starting_polarity_i)
                                 || actual_clk_state_i.events.falling_edge
                                 || (expected_clk_state_o.pause_active && ~pause_polarity_i);
    wire set_preemptive_clock_high = (set_polarity_i && starting_polarity_i)
                                  || (busy_delay_current && starting_polarity_i)
                                  || actual_clk_state_i.events.rising_edge
                                  || (expected_clk_state_o.pause_active && pause_polarity_i);

    clock_state preemptive_clock_state (
        .sys_dom_i             (sys_dom_i),
        .set_clock_low_i       (set_clock_low),
        .set_clock_high_i      (set_clock_high),
        .clock_active_i        (active_current),
        .clear_state_i         (busy_delay_current),
        .half_rate_elapsed_i   (preemptive_half_rate_elapsed),
        .quarter_rate_elapsed_i(preemptive_quarter_rate_elapsed),
        .pause_en_i            (pause_en_i),
        .pause_polarity_i      (pause_polarity_i),
        .state_o               (preemptive_clk_state_o)
    );

// Pause Violation Check
    assign pause_start_violation_o = pause_en_i && expected_clk_state_o.pause_active && ~preemptive_clk_state_o.pause_active;
    assign pause_stop_violation_o = ~pause_en_i && ~expected_clk_state_o.pause_active && preemptive_clk_state_o.pause_active;

endmodule : generation
