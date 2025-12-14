module rate_recovery (
    input                      common_p::clk_dom_s sys_dom_i,




    input                                          primary_event_i,
    input                                          secondary_event_i,




    output                                         locked_in_o,
    output [(clks_alot_p::RATE_COUNTER_WIDTH)-1:0] rate_o
);

/*
This module will have a free-running counter that resets during incoming events.
Primary events reset counter and submit current counter value into a `binary_value_prioritizer`
Secondary events reset counter

Bandpass and quarter-rate lockin need to be done her (quarter-rate is when you adjust the target range if you get something less than half of your rate but still within the band.... could be a series of 1s or 0s in an encoded data:clock)
*/

counter #(
    BIT_WIDTH()
) rate_counter (
    .sys_dom_i    (sys_dom_i),
    .counter_en_i (),
    .init_en_i    (),
    .decay_en_i   (),
    .seed_i       (),
    .growth_rate_i(),
    .decay_rate_i (),
    .clear_en_i   (),
    .count_o      ()
);

// Rate Bandpass Check //TODO:

// Rate Lockin/Filtering //TODO:

binary_value_prioritizer #(
    VALUE_BIT_WIDTH(),
    COUNT_BIT_WIDTH()
) rate_prioritizer (
    .sys_dom_i         (sys_dom_i),
    .clear_state_i     (),
    .growth_rate_i     (),
    .decay_rate_i      (),
    .saturation_limit_i(),
    .plateau_limit_i   (),
    .we_i              (),
    .data_i            (),
    .locked_in_o       (),
    .b_is_prioritized_o(),
    .data_o            (),
);

endmodule : rate_recovery
