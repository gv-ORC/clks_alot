/*
Current Features:


Desired Features:
    Clock Speed Recovery (Updates counter limit between edges)
    
Desiered Inputs:
    -> Recovery Enable
    -> Generation Enable
    - -> Starting Polarity
    - -> Generate Pause Enable (Preserves clock lock and phase, just negates the output)
    - -> Generate Pause Polarity

Desired Configurations
    -> [32b] (Common) sys_dom_i.clk Frequency
    -> [16b] (Recovery) Expected Half-Clock Uncertainty
    -> [16b] (Common) Desired Half-Clock Period
    ->  [8b] (Common) Preemtive Rising Edge & Steady High Cycle Count
    ->  [8b] (Common) Preemtive Falling Edge & Steady Low Cycle Count
    ->  [1b] Recovery Pause Polarity
    -> [16b] Minimum Pause Cycles (Using IO Domain Cycles)

Desired Flags:
    -> Reovery Violation, Over (Edge detected after expected cycle amount plus the uncertainty)
    -> Reovery Violation, Under (Edge detected before expected cycle amount minus the uncertainty)
    -> Maximum Frequency Violation (Half of IO Duty Cycle is less than the Maximum "preemtive delay"
    -> Minimum Frequency Violation (Counter overflows a target value between edges [configured as pos/neg/both] - Can also be from a pause)
    -> Pause Started (Raises after no edge [configured as pos/neg/both] has been detected for a target amount of time provided in IO Half-Cycles)
    - -> Pause Duration (Cycles since Pause Started has raised)

Clock Recovery Signals:
    -> Actual Steady Low, Sync to Rx Data
    -> Actual Steady High, Sync to Rx Data
    -> Actual Rising Edge, Sync to Rx Data
    -> Actual Falling Edge, Sync to Rx Data

    -> Expected Steady Low, Sync
    -> Expected Steady High, Sync
    -> Expected Rising Edge, Sync
    -> Expected Falling Edge, Sync

    -> Expected Steady Low, Preemitive
    -> Expected Steady High, Preemitive
    -> Expected Rising Edge, Preemitive
    -> Expected Falling Edge, Preemitive

Clock Generation Signals:
    -> Generated Steady Low, Sync
    -> Generated Steady High, Sync
    -> Generated Rising Edge, Sync
    -> Generated Falling Edge, Sync

    -> Generated Steady Low, Preemitive
    -> Generated Steady High, Preemitive
    -> Generated Rising Edge, Preemitive
    -> Generated Falling Edge, Preemitive

//!                                                                          //



*/
