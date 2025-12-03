module generation (
    input                   common_p::clk_dom sys_dom_i,

    //? Generation
    input                                     set_polarity_i,
    input                                     starting_polarity_i,

    input                                     generation_en_i, // When this goes low, clock will stop on the next starting_polarity
    //! NOTE: expected_half_rate should be AT LEAST `preemptive_delay + sync_cycle_offset + 1`
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] expected_half_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] expected_quarter_rate_minus_one_i,
    //! NOTE: Effective preemptive delay MUST be longer than `sync_cycle_offset` - By at least X????
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] preemptive_half_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] preemptive_quarter_rate_minus_one_i,
    // Pauses maintain clock phasing when enabling and disabling
    // Pauses enable & disable when clock polarity matches
    input                                     pause_en_i,
    input                                     pause_polarity_i, // Recovery will take care of polarity on its end for pauses as well

    //? Recovery
    // If desync comes in within 1 cycle of expected, skew the next event???
    // input                                     recovery_en_i, //! Take care of this in the clock sync system
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] sync_cycle_offset_i,
    input                                     negedge_sync_pulse_i,
    input                                     posedge_sync_pulse_i,

    //? Generated Clocks
    output                                    expected_clk_o,
    output        clks_alot_p::clock_events_s expected_clk_events_o,
    output                                    preemptive_clk_o,
    output        clks_alot_p::clock_events_s preemetive_clk_events_o
);

/*
? Generation Operation:
Cycle Counter     -- Toggle clock each half-rate
When `pause_en_i` -- Pause output during next matching polarity
Trigger `expected_clk_events_o` when local clock hits edge or middle of state
Trigger `preemetive_clk_events_o` when local clock hits edge or middle of state - Offset by `preemetive_cycle_count_i`

? During Recovery:
Cycle Counter -- Reset clock state during sync_pulses, set counter to `sync_cycle_offset_i` to account to input sync delay of incoming edge


! Case where `*_sync_pulse_i` comes in handy...
100 Mhz sys_dom_i, 10.0000 Mhz Expected IO, 10.0001 Mhz Actual... Clock will slowly skew lower, causing a sync pulse to move-up the core clock.

This means the minimum half-rate would be (preemptive_delay[5] + sync_cycle_offset_i[4] + 1) = 10... 
With 10 cycles being minimal...
> core clk - Max IO clk
       100 - 5Mhz
       150 - 7.5Mhz
       200 - 10Mhz
       250 - 12.5Mhz

TODO:
// 1. Sync Pulse Violation
// 2. Expected Pause Control
3. Preemptive Pause Control
// 4. Post-Enable Cleanup
// 4. Should we skew on re-sync? - No, cause the counter will automatically offset accordingly
// 5. Clock Event Generation

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

    wire                                      recovery_check = negedge_sync_pulse_i || posedge_sync_pulse_i;
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

// Clock Control, Common
    wire set_clock_low = (set_polarity_i && ~starting_polarity_i)
                      || busy_delay_current
                      || negedge_sync_pulse_i;
    wire set_clock_high = (set_polarity_i && ~starting_polarity_i)
                       || posedge_sync_pulse_i;

// Clock Control, Expected - Inherent 1 Cycle Delay to enforce phase-accurate pausing
    clock_state expected_clock_state (
        .sys_dom_i       (sys_dom_i),
        .set_clock_low_i (set_clock_low),
        .set_clock_high_i(set_clock_high),
        .clock_active_i  (active_current),
        .toggle_en_i     (expected_half_rate_elapsed),
        .pause_en_i      (pause_en_i),
        .pause_polarity_i(pause_polarity_i),
        .pause_active_o  (),
        .state_o         (expected_clk_o)
    );

    event_generation expected_event_generation (
        .sys_dom_i           (sys_dom_i),
        .clock_active_i      (active_current),
        .io_clk_i            (expected_clk_o),
        .half_rate_elapsed   (expected_half_rate_elapsed),
        .quarter_rate_elapsed(expected_quarter_rate_elapsed),
        .clk_events_o        (expected_clk_events_o)
    );

// Clock Control, Preemptive - Inherent 1 Cycle Delay to enforce phase-accurate pausing
    clock_state preemptive_clock_state (
        .sys_dom_i       (sys_dom_i),
        .set_clock_low_i (set_clock_low),
        .set_clock_high_i(set_clock_high),
        .clock_active_i  (active_current),
        .toggle_en_i     (preemptive_half_rate_elapsed),
        .pause_en_i      (pause_en_i),
        .pause_polarity_i(pause_polarity_i),
        .pause_active_o  (),
        .state_o         (preemptive_clk_o)
    );

    event_generation preemptive_event_generation (
        .sys_dom_i           (sys_dom_i),
        .clock_active_i      (active_current),
        .io_clk_i            (preemptive_clk_o),
        .half_rate_elapsed   (preemptive_half_rate_elapsed),
        .quarter_rate_elapsed(preemptive_quarter_rate_elapsed),
        .clk_events_o        (preemptive_clk_events_o)
    );

endmodule : generation
