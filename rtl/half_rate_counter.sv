    wire [(clks_alot_p::COUNTER_WIDTH-1):0] rate_counter_next = (sync_rst || filtered_event || clear_state_i)
                                                              ? clks_alot_p::COUNTER_WIDTH'(0)
                                                              : (rate_counter_current + clks_alot_p::COUNTER_WIDTH'(1));
    wire                                    rate_counter_trigger = sync_rst
                                                                || (clk_en && recovery_en_i)
                                                                || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (rate_counter_trigger) begin
            rate_counter_current <= rate_counter_next;
        end
    end

    reg  [(clks_alot_p::COUNTER_WIDTH)-1:0] prior_rate_current;
    wire [(clks_alot_p::COUNTER_WIDTH)-1:0] prior_rate_next = sync_rst
                                                            ? clks_alot_p::COUNTER_WIDTH'(0)
                                                            : rate_counter_current;
    wire                                    prior_rate_trigger = sync_rst
                                                              || (clk_en && recovery_en_i && filtered_event)
                                                              || (clk_en && clear_state_i);
    always_ff @(posedge clk) begin
        if (prior_rate_trigger) begin
            prior_rate_current <= prior_rate_next;
        end
    end
    assign current_rate_o = prior_rate_current;



/*
    1nd Rolling Counter
    2nd 

    Take the output of a counter during the proper events, if the value is roughly half the amount of the current value, accept 

*/