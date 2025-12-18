/**
 *  Module: clock_generation
 *
 *  About: 
 *
 *  Ports:
 *
**/
module clock_generation (
    input                     common_p::clk_dom_s sys_dom_i,

    input                                         generation_en_i,
    input                                         init_i,
    input                                         starting_polarity_i,
    input                                         clear_state_i,

    input [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] total_anticipation_i,
    input [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] counter_current_i,

// Delta Priotization Configuration & Control
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] growth_rate_i,
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] decay_rate_i,
    // `saturation_limit_i` needs to be at least 1 growth rate below the max allowed by `clks_alot_p::PRIORITIZE_COUNTER_WIDTH`
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] saturation_limit_i,
    // `plateau_limit_i` needs to be at greater-than or equal-to `decay_rate_i`
    input [(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)-1:0] plateau_limit_i,

    output                                              delta_mismatch_violation_o

// Recovery Feedback
    input         clks_alot_p::recovered_events_s recovered_events_i,
    input                                         fully_locked_in_i,
    input [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] high_rate_i,
    input [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] low_rate_i,
    input [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] full_rate_i, // ToDo: Add this signal to recovery

// Resulting Unpausable Clock
    output             clks_alot_p::clock_state_s unpausable_clk_state_o,

// Resulting Pausable Clock & Control
    input                                         pause_en_i,
    input                                         pause_polarity_i,
    output             clks_alot_p::clock_state_s pausable_clk_state_o,
    output                                        pause_start_violation_o,
    output                                        pause_stop_violation_o
);

// Clock Configuration
    wire clk = sys_dom_i.clk;
    wire clk_en = sys_dom_i.clk_en;
    wire sync_rst = sys_dom_i.sync_rst;

// Rate Tracking
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] target;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] active_half_rate;
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] inactive_half_rate;
    rate_tracking rate_tracking (
        .sys_dom_i             (sys_dom_i),
        .generation_en_i       (generation_en_i),
        .clear_state_i         (clear_state_i),
        .high_rate_i           (high_rate_i),
        .low_rate_i            (low_rate_i),
        .unpausable_clk_state_i(unpausable_clk_state_o),
        .counter_current_i     (counter_current_i),
        .target_o              (target),
        .active_half_rate_o    (active_half_rate),
        .inactive_half_rate_o  (inactive_half_rate),
    );

// Delta Generation
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] doubled_full_rate = {full_rate_i[(clks_alot_p::RATE_COUNTER_WIDTH)-2:0], 1'b0};
    wire   [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] full_and_a_half_rate = full_rate_i + active_half_rate_current;

    logic  [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] calculated_delta;
    wire                                     [1:0] calculated_delta_condition;
    assign                                         calculated_delta_condition[0] = (total_anticipation_i >= inactive_half_rate_current)
                                                                                || (total_anticipation_i >= full_and_a_half_rate);
    assign                                         calculated_delta_condition[1] = (total_anticipation_i >= full_rate_i)
                                                                                || (total_anticipation_i >= full_and_a_half_rate);

    always_comb begin : calculated_deltaMux
        case (calculated_delta_condition)
            2'b00  : calculated_delta = inactive_half_rate_current - total_anticipation_i; // Total Anticipation Less-Than or Equal-To Inactive Half-Rate
            2'b01  : calculated_delta = full_rate_i - total_anticipation_i;                // Total Anticipation Greater-Than Inactive Half-Rate
            2'b10  : calculated_delta = full_and_a_half_rate - total_anticipation_i;       // Total Anticipation Greater-Than Full-Rate
            2'b11  : calculated_delta = doubled_full_rate - total_anticipation_i;          // Total Anticipation Greater-Than (Full-Rate + Active Half-Rate)
            default: calculated_delta = clks_alot_p::RATE_COUNTER_WIDTH'(0);
        endcase
    end

// Delta Tracking
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] actual_delta = total_anticipation_i - counter_current_i;

    wire                                         rising_delta_we = fully_locked_in_i && recovered_events_i.rising_edge;
    wire                                         rising_delta_locked;
    wire                                         rising_b_is_prioritized; // ToDo: Is this needed?
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] anticipated_rising_delta;
    binary_value_prioritizer #(
        VALUE_BIT_WIDTH(clks_alot_p::RATE_COUNTER_WIDTH),
        COUNT_BIT_WIDTH(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)
    ) rising_delta_prioritizer (
        .sys_dom_i         (sys_dom_i),
        .clear_state_i     (clear_state_i),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_limit_i   (plateau_limit_i),
        .we_i              (rising_delta_we),
        .data_i            (actual_delta),
        .locked_in_o       (rising_delta_locked),
        .b_is_prioritized_o(b_is_prioritized),
        .data_o            (anticipated_rising_delta)
    );

    wire                                         falling_delta_we = fully_locked_in_i && recovered_events_i.falling_edge;
    wire                                         falling_delta_locked;
    wire                                         falling_b_is_prioritized; // ToDo: Is this needed?
    wire [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] anticipated_falling_delta;
    binary_value_prioritizer #(
        VALUE_BIT_WIDTH(clks_alot_p::RATE_COUNTER_WIDTH),
        COUNT_BIT_WIDTH(clks_alot_p::PRIORITIZE_COUNTER_WIDTH)
    ) falling_delta_prioritizer (
        .sys_dom_i         (sys_dom_i),
        .clear_state_i     (clear_state_i),
        .growth_rate_i     (growth_rate_i),
        .decay_rate_i      (decay_rate_i),
        .saturation_limit_i(saturation_limit_i),
        .plateau_limit_i   (plateau_limit_i),
        .we_i              (falling_delta_we),
        .data_i            (actual_delta),
        .locked_in_o       (falling_delta_locked),
        .b_is_prioritized_o(b_is_prioritized),
        .data_o            (anticipated_falling_delta)
    );

    assign unpausable_clk_state_o.status.locked = rising_delta_locked && falling_delta_locked;

// Delta Error
    assign delta_mismatch_violation_o = ((calculated_delta != anticipated_rising_delta) && recovered_events_i.rising_edge)
                                     || ((calculated_delta != anticipated_falling_delta) && recovered_events_i.falling_edge);

// Clock DFF
    wire half_target_reached = target == counter_current_i;
    wire quarter_target_reached = target == counter_current_i;

    reg  clock_current;
    wire clock_next = (init_i || sync_rst || clear_state_i)
                    ? starting_polarity_i
                    : ~clock_current;
    wire clock_trigger = sync_rst
                      || (clk_en && init_i)
                      || (clk_en && sync_rst)
                      || (clk_en && clear_state_i)
                      || (clk_en && generation_en_i && target_reached);
    always_ff @(posedge clk) begin
        if (clock_trigger) begin
            clock_current <= clock_next;
        end
    end

// Pause Control (Only mutes pausable output.... Pause needs to start in the Preemptive, then goes into the expected... so they can stop on the same edge)

// Event Generation
    event_generation event_generation (
        .sys_dom_i             (sys_dom_i),
        .clock_active_i        (),
        .io_clk_i              (),
        .half_rate_elapsed_i   (),
        .quarter_rate_elapsed_i(),
        .clk_events_o          (),
    );

endmodule : clock_generation
