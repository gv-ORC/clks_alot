/**
 * Package: clks_alot_p
 * 
 * Package for the sir_clks_alot
 * 
 * Giovanni Viscardi 2/Dec/2025
**/

package clks_alot_p;

    parameter COUNTER_WIDTH = 32;


    typedef struct packed {
        logic                     recovery_over_violation;
        logic                     recovery_under_violation;
        logic                     minimim_frequency_violation;
        logic                     maximim_frequency_violation;
        logic                     pause_active;
        logic [COUNTER_WIDTH-1:0] pause_duration; // In IO Cycles
    } clock_status_s;

    typedef struct packed {
        logic rising_edge;
        logic steady_high;
        logic falling_edge;
        logic steady_low;
    } clock_events_s;

























//! ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~


    parameter SYS_CLOCK_MULTIPLE = 64;
    parameter CLOCK_EDGE_UNCERTANTY = 1;
    parameter SHORT_PAUSE_CYCLE_COUNT = 6;
    parameter LONG_PAUSE_CYCLE_COUNT = 60;
    parameter TARGET_SHORT_LENGTH = SYS_CLOCK_MULTIPLE * SHORT_PAUSE_CYCLE_COUNT;
    parameter UNCERTAIN_SHORT_LENGTH = TARGET_SHORT_LENGTH - (SHORT_PAUSE_CYCLE_COUNT * CLOCK_EDGE_UNCERTANTY * 2);
    parameter TARGET_LONG_LENGTH = SYS_CLOCK_MULTIPLE * LONG_PAUSE_CYCLE_COUNT;
    parameter UNCERTAIN_LONG_LENGTH = TARGET_LONG_LENGTH - (LONG_PAUSE_CYCLE_COUNT * CLOCK_EDGE_UNCERTANTY * 2);
    parameter CYCLE_BITWIDTH = (UNCERTAIN_SHORT_LENGTH == 0) ? 1 : $clog2(UNCERTAIN_SHORT_LENGTH);
    parameter TARGET_EDGE_CYCLE_COUNT = (SYS_CLOCK_MULTIPLE/2);
    parameter MINIMUM_EDGE_CYCLE_COUNT = TARGET_EDGE_CYCLE_COUNT - CLOCK_EDGE_UNCERTANTY;
    parameter MAXIMUM_EDGE_CYCLE_COUNT = TARGET_EDGE_CYCLE_COUNT + CLOCK_EDGE_UNCERTANTY;
    parameter MINIMUM_MISSED_EDGES_TO_START_PAUSE = 4;
    parameter PAUSE_START_LENGTH = MINIMUM_MISSED_EDGES_TO_START_PAUSE * SYS_CLOCK_MULTIPLE;
    parameter TRANSMITTED_BITS = 16;
    parameter CYCLES_PER_BIT = 2;
    parameter NEGEDGES_BETWEEN_SHORT_PAUSES = TRANSMITTED_BITS * CYCLES_PER_BIT;
    parameter NEGEDGE_BITWIDTH = (NEGEDGES_BETWEEN_SHORT_PAUSES == 0) ? 1 : $clog2(NEGEDGES_BETWEEN_SHORT_PAUSES);

    typedef struct packed {

    } initialize_s;

    typedef struct packed {
        logic clk;
        logic addr;
        logic data_high;
        logic data_low;
    } interface_s ;
    parameter INTERFACE_WIDTH = $bits(interface_s);

    typedef struct packed {
        logic clk;
        logic clk_lock;
    } interface_clock_s;
    parameter INTERFACE_CLOCK_WIDTH = $bits(interface_clock_s);

endpackage
