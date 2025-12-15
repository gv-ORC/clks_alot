/*
! Insta-Sync Drift]
? Mimic Not 50-50: Low Half-Rate 2(h), High Half-Rate 2(l), Starts at (s) = 10, Rx Delay (r) = 3, Tx Delay (t) = 3, Counter(c), Drift Window (w) = 1
* Incoming - The clock signal from the pin after it has been properly syncronized and had events extracted
* Drift(d) - 
*          > Seed Drift by: [@f1] <= c + h + l
* Expected(e) - Generated clock that mimics the cycle that the clock would have arrived directly at the Rx Pin
*             > Seed Expected by: [@f1]+1 <= (d + h + l) - r
* Premptive - Generated clock that triggers events earlier than the pin, to account for pipeline and sync latency
*           > Seed Preemptive by: [@f1]+1 <= e - t

>NOTE: (r + w) <= (h + l) 
                                                                                                       Neg Drift                    Neg Drift                        Pos Drift                        Pos Drift
Incoming Edge Name:                                f0    r0    f1    r1    f2    r2    f3    r3    f4    r4(f5)   r5    f6    r6    f7(r7)   f8    r8    f9    r9      (f10)  r10  f11    r11   f12     (r12)  f13   r13   f14   r14
Incoming Clock:               xxxxxxx---------------______------______------______------______------______---______------______------___------______------______---------______------______------_________------______------______------
Counter(c):                   0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
Drift Edge Name:                                                           f2    r2    f3    r3    f4    r4(f5)   r5    f6    r6    f7(r7)   f8    r8    f9    r9      (f10)  r10  f11    r11   f12     (r12)  f13   r13   f14   r14
Drift Clock (fake):           xxxxxxxxxxxxxxxxxxxxxx------------------------______------______------______---______------______------___------______------______---------______------______------_________------______------______------
Drift High Half-Rate:         x x x x x x x x x x x  -  -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Drift Low Half-Rate:          x - - - - - - - - - -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Drift Event Upper Limit:      x x x x x x x x x x x  -  -  -  -  17 17 17 17 19 19 21 21 23 23 25 25 27 27 29 32 32 34 34 36 36 38 38 40 41 41 43 43 45 45 47 47 49 49 49 52 52 54 54 56 56 58 58 60 60 60 63 63 65 65 67 67 69 69 71 71
Drift Target:                 x x x x x x x x x x x  -  -  -  -  18 18 18 18 20 20 22 22 24 24 26 26 28 28 30 31 31 33 33 35 35 37 37 39 40 40 42 42 44 44 46 46 48 48 48 51 51 53 53 55 55 57 57 59 59 59 62 62 64 64 66 66 68 68 70 70
Drift Event Lower Limit:      x x x x x x x x x x x  -  -  -  -  19 19 19 19 21 21 23 23 25 25 27 27 29 29 31 30 30 32 32 34 34 36 36 38 39 39 41 41 43 43 45 45 47 47 47 50 50 52 52 54 54 56 56 58 58 58 61 61 63 63 65 65 67 67 69 69
Drift:Expected Limit Delta:   x x x x x x x x x x x  -  -  -  -  -  1  1  1  -1 1  -1 1  -1 1  -1 1  -1 1  -1 -1 1  -1 1  -1 1  -1 1  -1 -1 1  -1 1  -1 1  -1 1  -1 1  1  -1 1  -1 1  -1 1  -1 1  -1 1  1  -1 1  -1 1  -1 1  -1 1  -1 1
Drift:Preemptive Limit Delta: x x x x x x x x x x x  -  -  -  -  -  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  2  0  0  0  0  0  0  0  0  0  0  2  0
Expected Edge Name:                                                           f3    r3    f4    r4    f5    r5(f6)    r6    f7    r7   f8(r8)   f9    r9    f10   r10     (f11)  r11   f12   r12   f13      (r13) f14   r14   f15   r15
Expected Clock:               xxxxxxxxxxxxxxxxxxxxxx---------------------------______------______------______---______------______------___------______------______---------______------______------_________------______------______---
Expected Half-Rate Limit:     x x x x x x x x x x x  -  -  -  -  -  19 19 19 19 21 21 23 23 25 25 27 27 29 29 30 32 32 34 34 36 36 38 38 39 41 41 43 43 45 45 47 47 49 49 50 52 52 54 54 56 56 58 58 60 60 61 63 63 65 65 67 67 69 69 71
Preemptive Edge Name:                                                            f4    r4    f5    r5    f6(r6)  f7    r7    f8    r8(f9)   r9    f10   r10   f11   r11     (f12)  r12   f13   r13   f14     (r14)  f15   r15   f16
Preemptive Clock:             xxxxxxxxxxxxxxxxxxxxxx------------------------------______------______------___------______------______---______------______------______---------______------______------_________------______------______
Preemptive Half-Rate Limit:   x x x x x x x x x x x  -  -  -  -  -  20 20 20 20 20 22 22 24 24 26 26 28 28 30 31 31 33 33 35 35 37 37 39 40 40 42 42 44 44 46 46 48 48 50 51 51 53 53 55 55 57 57 59 59 61 62 62 64 64 66 66 68 68 70 70
*/

module drift_clock (
    input                 common_p::clk_dom_s sys_dom_i,
    input  
);



endmodule : drift_clock
