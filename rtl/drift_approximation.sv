/*
// Drift Frequency
    FIFO that tracks the last n prior drifts (max 64, power of 2 only, have rolling avg system) and finds the avg amount of cycles between each drift,
    Apply this drift during missing edges if applicable, to more likely be aligned after a series of missing bits.

*/