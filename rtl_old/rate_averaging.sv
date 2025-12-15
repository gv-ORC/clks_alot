/*
Average over the last N rates (by having the tail of a FIFO being a max distance away from the head)
Add new values, subtract old, divide by the amount of values (divide by powers of 2 only to utilize shifting)

During wind-up, using as deep as you can and raise `wound_up` once the averaging has reached the desired depth.

This module will be a generic.. but for the clocking stuff:
    Averaging depth should be less than the anticipated edges between singluar drift events...

*/