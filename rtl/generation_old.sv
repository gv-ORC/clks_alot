module generation (
    input                   common_p::clk_dom_s sys_dom_i,

    //? Generation
    input                                     set_polarity_i,
    input                                     starting_polarity_i,

    input                                     generation_en_i, // When this goes low, clock will stop on the next starting_polarity
    output                                    busy_o,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] expected_half_rate_minus_two_i, // change every half-rate pulse, and you can get PWM
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] expected_quarter_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] preemptive_half_rate_minus_one_i,
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] preemptive_quarter_rate_minus_one_i,

    //? Recovery - To accomodate for skew/drift
    input  [(clks_alot_p::COUNTER_WIDTH)-1:0] sync_cycle_offset_i,
    input          clks_alot_p::clock_state_s actual_clk_state_i, // for "Clock came too Early"

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

/* 
* Approximations *
Rx Sync Buffer: 3 (sync_cycle_offset_i)
Clock Recovery: 1
Clock Config: 1
Clock Gen Delay: 1
Tx Logic: 1 (+1?)
Tx Buffer: 1(2) (only takes 1 cycle, but we add an extra to account for slip... slip needs to be adjustable based on speed... super slow clocks may have HUGE slip)
Sync Buffer: 1* (Doesnt Count, this is our "sync bound" - data is gaurenteed to be stable for this clock as the timing for the internal register will made to meet sys_clk... as long as slip is set correctly)
> Total Preemptive Anticipation: 8 Cycles (preemtive_cycle_count)

Minimum Half-Rate == Preemptive Anticipation

Core Clock -> IO Clock
   100 Mhz -> 6.25 Mhz
   200 Mhz -> 12.5 Mhz

Use larger counters... allow the clocks to overlap
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

// Clock Event Detection and Correction
    reg  [(clks_alot_p::COUNTER_WIDTH)-1:0] cycle_count_current;

    reg  half_rate_delay_current;
    wire expected_half_rate_elapsed = cycle_count_current == expected_half_rate_minus_two_i;
    wire nudge_check = actual_clk_state_i.events.falling_edge || actual_clk_state_i.events.rising_edge;
    wire half_rate_delay_next = ~sync_rst && expected_half_rate_elapsed && ~busy_delay_current;
    wire half_rate_delay_trigger = sync_rst
                                || (clk_en && clock_active_i && expected_half_rate_elapsed) // Set
                                || (clk_en && clock_active_i && nudge_check) // Clear
                                || (clk_en && busy_delay_current);
    always_ff @(posedge clk) begin
        if (half_rate_delay_trigger) begin
            half_rate_delay_current <= half_rate_delay_next;
        end
    end

    wire expected_quarter_rate_elapsed = cycle_count_current == expected_quarter_rate_minus_one_i;
    wire preemptive_half_rate_elapsed = cycle_count_current == preemptive_half_rate_minus_one_i;
    wire preemptive_quarter_rate_elapsed = cycle_count_current == preemptive_quarter_rate_minus_one_i;

    wire stall_check = half_rate_delay_current ^ nudge_check;

// Cycle Counter
    logic  [(clks_alot_p::COUNTER_WIDTH)-1:0] cycle_count_next;
    wire                                [1:0] cycle_count_next_condition;
    assign                                    cycle_count_next_condition[0] = nudge_check;
    assign                                    cycle_count_next_condition[1] = half_rate_delay_current || sync_rst || busy_delay_current;
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

    clock_generation expected_clock_state (
        .sys_dom_i             (sys_dom_i),
        .set_clock_low_i       (set_expected_clock_low),
        .set_clock_high_i      (set_expected_clock_high),
        .clock_active_i        (active_current),
        .clear_state_i         (busy_delay_current),
        .half_rate_elapsed_i   (expected_half_rate_elapsed),
        .quarter_rate_elapsed_i(expected_quarter_rate_elapsed),
        .unpausable_state_o    (unpausable_expected_clk_state_o),
        .pause_en_i            (pause_en_i),
        .pause_polarity_i      (pause_polarity_i),
        .pausable_state_o      (pausable_expected_clk_state_o)
    );

    wire expected_pause_active_pulse;

    monostable_full #(
        .BUFFERED(1'b0)
    ) expected_pause_monostable_gen (
        .clk_dom_s_i      (sys_dom_i),
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

    clock_generation preemptive_clock_state (
        .sys_dom_i             (sys_dom_i),
        .set_clock_low_i       (set_clock_low),
        .set_clock_high_i      (set_clock_high),
        .clock_active_i        (active_current),
        .clear_state_i         (busy_delay_current),
        .half_rate_elapsed_i   (preemptive_half_rate_elapsed),
        .quarter_rate_elapsed_i(preemptive_quarter_rate_elapsed),
        .unpausable_state_o    (unpausable_preemptive_clk_state_o),
        .pause_en_i            (pause_en_i),
        .pause_polarity_i      (pause_polarity_i),
        .pausable_state_o      (pausable_preemptive_clk_state_o)
    );

// Pause Violation Check
    assign pause_start_violation_o = pause_en_i && expected_clk_state_o.pause_active && ~preemptive_clk_state_o.pause_active;
    assign pause_stop_violation_o = ~pause_en_i && ~expected_clk_state_o.pause_active && preemptive_clk_state_o.pause_active;

endmodule : generation
