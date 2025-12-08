/*
// Drift Frequency
    FIFO that tracks the last 1, 2, or 4 prior drifts and finds the avg amount of cycles between each drift,
    Apply this drift during missing edges if applicable, to more likely be aligned after a series of missing bits.

*/