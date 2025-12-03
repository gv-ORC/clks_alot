    input                                     pause_en_i,
    input                                     pause_polarity_i, // Recovery will take care of polarity on its end for pauses as well
    // input  [(clks_alot_p::COUNTER_WIDTH)-1:0] half_rate_uncertainty_i, //! Handle in recover.sv
    // input  [(clks_alot_p::COUNTER_WIDTH)-1:0] minimum_pause_length_i, //! Handle in recover.sv