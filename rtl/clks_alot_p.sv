/**
 * Package: clks_alot_p
 * 
 * Package for sir_clks_alot
 * 
 * Giovanni Viscardi 2/Dec/2025
**/

package clks_alot_p;

// Common Parameters
    //TODO: make these $clog2 based on max values
    parameter RATE_COUNTER_WIDTH = 32;
    parameter DRIFT_COUNTER_WIDTH = 8;

    parameter PRIORITIZE_COUNTER_WIDTH = 8;

// Configuration Structs
    typedef struct packed {
        // 0: Use High and Low rates respectively
        // 1: Only use High rates respectively
        logic even_50_50_en;
        /*
        TODO: Update these diagrams to represent the newest filtering and lockin systems
        | = Desired Rate
        { = Minimum Violation Rate (Lock-In effected)
        } = Maximum Violation Rate (Lock-In effected)
        < = Minimum Band Rate
        > = Maximum Band Rate
        - = Allowed Rate
        x = Ignored Rate
        v = Violation Triggered Rate
        
        Unpausable:
            Current
            xxx{vvv<---|--->vvv}xxx
            xxx{vvvv<--|-->vvvv}xxx
            xxx{vvvvv<-|->vvvvv}xxx

        Pausable:
                   At most half : Current
            xxx{vvv<---|--->vvv...vvv<---|--->vvv}xxx
            xxx{vvvv<--|-->vvvv...vvvv<--|-->vvvv}xxx
            xxx{vvvvv<-|->vvvvv...vvvvv<-|->vvvvv}xxx
        */
        logic lockin_enabled;
        // Used when recovering a clock from a data signal
        logic cycle_skip_en;
    } duty_cycle_mode_s;

    typedef enum logic {
        PIN_CAME_LATE,
        PIN_CAME_EARLY
    } drift_direction_e;

    parameter MAX_RATE_AVERAGING_DEPTH = 1024; // Powers of 2 only
    parameter MAX_AVG_DEPTH_WIDTH = (MAX_RATE_AVERAGING_DEPTH == 1)
                                  ? 1
                                  : $clog2(MAX_RATE_AVERAGING_DEPTH);
    typedef struct packed {
        logic  [RATE_COUNTER_WIDTH-1:0] drift_window;
        logic                           fixed_drift_direction_en;
        // 0: Only allow a single drift direction
        // 1: Allow both shift directions
        logic                           full_drift_direction_en;
        drift_direction_e               fixed_drift_direction;
        logic  [RATE_COUNTER_WIDTH-1:0] lockin_rate;
        logic  [RATE_COUNTER_WIDTH-1:0] maximum_band_minus_one;
        logic  [RATE_COUNTER_WIDTH-1:0] minimum_band_minus_one;
        logic  [RATE_COUNTER_WIDTH-1:0] required_lockin_duration;
        logic [MAX_AVG_DEPTH_WIDTH-1:0] rate_averaging_depth; // Powers of 2 only
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
    typedef enum logic { 
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

// Operational Structs
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
        logic any_valid_edge;
        logic diff_rising_edge_violation;
        logic diff_falling_edge_violation;
    } recovered_events_s;

    typedef struct packed {
        logic [RATE_COUNTER_WIDTH-1:0] high_rate;
        logic [RATE_COUNTER_WIDTH-1:0] low_rate;
        logic                          over_frequency_violation;
        logic                          under_frequency_violation;
    } recovered_half_rates_s;

    typedef struct packed {
        logic                          pause_active;
        logic [RATE_COUNTER_WIDTH-1:0] pause_duration; // In recovered IO Cycles
        logic                          locked;
    } status_s;

    typedef struct packed {
        logic rising_edge;
        logic steady_high;
        logic falling_edge;
        logic steady_low;
    } generated_events_s;

    typedef struct packed {
        logic              clk;
        status_s           status;
        generated_events_s events;
    } clock_state_s;

endpackage
