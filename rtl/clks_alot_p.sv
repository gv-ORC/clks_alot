/**
 * Package: clks_alot_p
 * 
 * Package for sir_clks_alot
 * 
 * Giovanni Viscardi 2/Dec/2025
**/

package clks_alot_p;

// Common Parameters
    parameter COUNTER_WIDTH = 32;

// Recovery
    typedef struct packed {
        // 0: Use High and Low rates respectively
        // 1: Only use High rates respectively
        logic even_50_50_en;
        /*
        | = Desired Rate
        { = Minimum Violation Rate (Lock-In effected)
        } = Maximum Violation Rate (Lock-In effected)
        < = Minimum Band Rate
        > = Maximum Band Rate
        - = Allowed Rate
        x = Ignored Rate
        v = Violation Triggered Rate
        
        Locking-in:
        xxx{vvv<---|--->vvv}xxx
        xxx{vvvv<--|-->vvvv}xxx
        xxx{vvvvv<-|->vvvvv}xxx
        */
        logic lockin_enabled;
        // Used when recovering a clock from a data signal
        logic cycle_skip_en;
    } duty_cycle_mode_s;

    typedef struct packed {
        logic [COUNTER_WIDTH-1:0] half_lockin_window_minus_one;
        logic [COUNTER_WIDTH-1:0] maximum_violation_minus_one;
        logic [COUNTER_WIDTH-1:0] minimum_violation_minus_one;
        logic [COUNTER_WIDTH-1:0] maximum_band_minus_one;
        logic [COUNTER_WIDTH-1:0] minimum_band_minus_one;
    } half_rate_limits_s;

    typedef struct packed {
        duty_cycle_mode_s  mode;
        half_rate_limits_s high_limits;
        half_rate_limits_s low_limits;
    } duty_cycle_conf_s;

    // TODO: clean up these comments...
    /*
       SINGLE_CONTINUOUS - Single Continuous clocks, pauses throw errors
                         > Basic Monostable - sense_i = io_clk_i[0]
         SINGLE_PAUSABLE - Single Continuous, pause status forwarded
                         > Basic Monostable - sense_i = io_clk_i[0]
          DIF_CONTINUOUS - Differential Clock Pair, pauses throw errors
                         > Basic Monostable - (sense_i = io_clk_i[0]) & (sense_i = io_clk_i[1]) When opposing edges both fire, if mismatch: throw violation
                         > FORCES `even_50_50_en`
            DIF_PAUSABLE - Differential Clock Pair, pause status forwarded
                         > Basic Monostable -(sense_i = io_clk_i[0]) & (sense_i = io_clk_i[1]) When opposing edges both fire, if mismatch: throw violation
                         > FORCES `even_50_50_en`
         QUAD_CONTINUOUS - Differential Data Pair, pauses throw errors
                         > Basic Monostable - (sense_i = io_clk_i[0]) & (sense_i = io_clk_i[1]) When opposing edges both fire, mismatches use dedicated events
                         > FORCES `even_50_50_en`
           QUAD_PAUSABLE - Differential Data Pair, pause status forwarded
                         > Basic Monostable - (sense_i = io_clk_i[0]) & (sense_i = io_clk_i[1]) When opposing edges both fire, mismatches use dedicated events
                         > FORCES `even_50_50_en`
    */
    typedef enum { 
        SINGLE_CONTINUOUS,
        SINGLE_PAUSABLE,
        DIF_CONTINUOUS,
        DIF_PAUSABLE, // If using Data, Pause duration should be longer than the longest stretch of possible 0s/1s in a data-frame
        QUAD_CONTINUOUS,
        QUAD_PAUSABLE
    } input_mode_s;

    typedef struct packed {
        input_mode_s      mode;
        duty_cycle_conf_s duty_cycle;
    } recovery_conf_s;

    typedef struct packed {
        logic pos;
        logic neg;
    } recovery_pins_s;

    typedef struct packed {
        logic primary;
        logic secondary;
    } recovery_drivers_s;

    typedef struct packed {
        logic primary_rising_edge;
        logic primary_falling_edge;
        logic primary_either_edge;
        logic secondary_rising_edge;
        logic secondary_falling_edge;
        logic secondary_either_edge;
    } driver_events_s;

    typedef struct packed {
        logic rising_edge;
        logic falling_edge;
        // logic dual_high_edge; //! These are only used when recovering data, not clocks
        // logic dual_low_edge; //! These are only used when recovering data, not clocks
        logic any_valid_edge;
        logic diff_rising_edge_violation;
        logic diff_falling_edge_violation;
    } recovered_events_s;

    typedef struct packed {
        logic [COUNTER_WIDTH-1:0] high_rate;
        logic [COUNTER_WIDTH-1:0] low_rate;
        logic                     over_frequency_violation;
        logic                     under_frequency_violation;
    } recovered_half_rates_s;

// Common
    typedef struct packed {
        logic                     pause_active;
        logic [COUNTER_WIDTH-1:0] pause_duration; // In recovered IO Cycles
        logic                     locked;
    } status_s;

// Generation
    typedef struct packed {
        logic rising_edge;
        logic steady_high;
        logic falling_edge;
        logic steady_low;
    } generated_events_s;

    typedef struct packed {
        logic                     clk;
        status_s                  status;
        generated_events_s        events;
    } clock_state_s;

endpackage
