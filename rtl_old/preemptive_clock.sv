/*
! Insta-Sync Drift]
? Mimic Not 50-50: Low Half-Rate 2(h), High Half-Rate 2(l), Starts at (s) = 10, Rx Delay (r) = 3, Tx Delay (t) = 3, Counter(c), Drift Window (w) = 1
* Incoming - The clock signal from the pin after it has been properly syncronized and had events extracted
* Drift(d) - 
*          > Seed Drift by: [@f1] <= (c + h + l) - 1 ,,, Cycle 15 is the cycle that the edge is detected, add h and l, to get 19, subtract 1 since the edge was directly between the last and current cycle
*          > Update on Rising Edges: h - 1
*          > Update on Falling Edges: l - 1
* Expected(e) - Generated clock that mimics the cycle that the clock would have arrived directly at the Rx Pin
*             > Seed Expected by: [@f1]+1 <= (d + h + l) - r
*             > Sync Delta on Rising Edge by: h - r //! Validate this once we go to longer clock periods
*             > Seed Delta on Falling Edge by: l - r //! Validate this once we go to longer clock periods
* Premptive - Generated clock that triggers events earlier than the pin, to account for pipeline and sync latency
*           > Seed Preemptive by: [@f1]+1 <= e - t
*           > Sync Delta on Rising Edge by:  //! Validate this once we go to longer clock periods
*           > Seed Delta on Falling Edge by:  //! Validate this once we go to longer clock periods

>NOTE: (r + w) <= (h + l)
>NOTE: (t + w) <= (h + l)
                                                                                   Seed Sync   Start Sync  Neg Drift                  Neg Drift                       Pos Drift                        Pos Drift
Incoming Edge Name:                                f0    r0    f1    r1    f2    r2   [f3]    r3   [f4]    r4(f5)   r5    f6    r6    f7(r7)   f8    r8    f9    r9    (f10)  r10  f11    r11   f12     (r12)  f13   r13   f14   r14
Incoming Clock:               xxxxxxx---------------______------______------______------______------______---______------______------___------______------______---------______------______------_________------______------______------
Counter(c):                   0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
Drift High Half-Rate:         x x x x x x x x x x x  -  -  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Drift Low Half-Rate:          x x x x x x x x x x x  -  -  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2
Drift Event Upper Limit:      x x x x x x x x x x x  -  -  -  -  17 17 17 17 19 19 21 21 23 23 25 25 27 27 29 32 32 34 34 36 36 38 38 40 41 41 43 43 45 45 47 47 49 49 49 52 52 54 54 56 56 58 58 60 60 60 63 63 65 65 67 67 69 69 71 71
Drift Target:                 x x x x x x x x x x x  -  -  -  -  18 18 18 18 20 20 22 22 24 24 26 26 28 28 30 31 31 33 33 35 35 37 37 39 40 40 42 42 44 44 46 46 48 48 48 51 51 53 53 55 55 57 57 59 59 59 62 62 64 64 66 66 68 68 70 70
Drift Event Lower Limit:      x x x x x x x x x x x  -  -  -  -  19 19 19 19 21 21 23 23 25 25 27 27 29 29 31 30 30 32 32 34 34 36 36 38 39 39 41 41 43 43 45 45 47 47 47 50 50 52 52 54 54 56 56 58 58 58 61 61 63 63 65 65 67 67 69 69
Drift:Expected Limit Delta:   x x x x x x x x x x x  -  -  -  -  -  -1 -1 1  -1 1  -1 1  -1 1  -1 1  -1 1  -1 -1 1  -1 1  -1 1  -1 1  -1 -1 1  -1 1  -1 1  -1 1  -1 1  1  -1 1  -1 1  -1 1  -1 1  -1 1  1  -1 1  -1 1  -1 1  -1 1  -1 1
Drift:Preemptive Limit Delta: x x x x x x x x x x x  -  -  -  -  -  -1 2  2  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  2  0  0  0  0  0  0  0  0  0  0  0  2  0  0  0  0  0  0  0  0  0  0
Drift Edge Name:                                                           f2    r2    f3    r3    f4    r4(f5)   r5    f6    r6    f7(r7)   f8    r8    f9    r9      (f10)  r10  f11    r11   f12     (r12)  f13   r13   f14   r14
Drift Clock (fake):           xxxxxxxxxxxxxxxxxxxxxx------------------------______------______------______---______------______------___------______------______---------______------______------_________------______------______------
Expected Edge Name:                                                           f3    r3    f4    r4    f5    r5(f6)    r6    f7    r7   f8(r8)   f9    r9    f10   r10     (f11)  r11   f12   r12   f13      (r13) f14   r14   f15   r15
Expected Clock:               xxxxxxxxxxxxxxxxxxxxxx---------------------------______------______------______---______------______------___------______------______---------______------______------_________------______------______---
Expected Half-Rate Limit:     x x x x x x x x x x x  -  -  -  -  -  19 19 19 19 21 21 23 23 25 25 27 27 29 29 30 32 32 34 34 36 36 38 38 39 41 41 43 43 45 45 47 47 49 49 50 52 52 54 54 56 56 58 58 60 60 61 63 63 65 65 67 67 69 69 71
Preemptive Edge Name:                                                f3    r3    f4    r4    f5    r5    f6(r6)   f7    r7    f8    r8(f9)   r9    f10   r10   f11   r11     (f12)  r12   f13   r13   f14     (r14)  f15   r15   f16
Preemptive Clock:             xxxxxxxxxxxxxxxxxxxxxx------------------______------______------______------___------______------______---______------______------______---------______------______------_________------______------______
Preemptive Half-Rate Limit:   x x x x x x x x x x x  -  -  -  -  -  16 20 20 20 20 22 22 24 24 26 26 28 28 30 31 31 33 33 35 35 37 37 39 40 40 42 42 44 44 46 46 48 48 50 51 51 53 53 55 55 57 57 59 59 61 62 62 64 64 66 66 68 68 70 70

! Insta-Sync Drift
? Mimic Not 50-50: Low Half-Rate 5(h), High Half-Rate 5(l), Starts at (s) = 10, Rx Delay (r) = 3, Tx Delay (t) = 3, Counter(c), Drift Window (w) = 1  -- hl indicates either High or Low rate
* Incoming - The clock signal from the pin after it has been properly syncronized and had events extracted
* Drift(d) - 
*          > Seed Drift by: [@f1] <= (c + h + l) - 1 ,,, Cycle 15 is the cycle that the edge is detected, add h and l, to get 19, subtract 1 since the edge was directly between the last and current cycle
*          > Update on Rising Edges: h - 1
*          > Update on Falling Edges: l - 1
* Expected(e) - Generated clock that mimics the cycle that the clock would have arrived directly at the Rx Pin
*             > Seed Expected by: [@f1]+1 <= (d + 2h + 2l) - r - 1*  [-1 is optional based on how the logic is done]
*             > Sync Delta on Rising Edge by: (r > hl) ? (hl - r) : ((h + l) - 2r)
* Premptive - Generated clock that triggers events earlier than the pin, to account for pipeline and sync latency
*           > Seed Preemptive by: [@f1]+1 <= (d + 2h + 2l) - r - t - 1*  [-1 is optional based on how the logic is done]
*           > Sync Delta on Rising Edge by: (r > hl) ? ((???????????????????) - r - t) : (hl - r - t)

>NOTE: (r + w) <= (h + l) 
                                                                                                                                         Seed Sync                     Start Sync                   Neg Drift
Incoming Edge Name:                                f0             r0             f1             r1             f2             r2            [f3]            r3            [f4]            r4         (f5)            r5             f6
Incoming Clock:               xxxxxxx---------------_______________---------------_______________---------------_______________---------------_______________---------------_______________------------_______________---------------___
Counter(c):                   0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
Drift High Half-Rate:         x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5
Drift Low Half-Rate:          x x x x x x x x x x x  -  -  -  -  -  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5 
Drift Event Upper Limit:      x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  31 31 31 31 31 31 31 31 31 31 36 36 36 36 36 41 41 41 41 41 46 46 46 46 46 51 51 51 51 51 56 56 56 56 56 61 61 61 61 65 65 65 65 65 70 70 70 70 70 75
Drift Target:                 x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  30 30 30 30 30 30 30 30 30 30 35 35 35 35 35 40 40 40 40 40 45 45 45 45 45 50 50 50 50 50 55 55 55 55 55 60 60 60 60 64 64 64 64 64 69 69 69 69 69 74
Drift Event Lower Limit:      x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  29 29 29 29 29 29 29 29 29 29 34 34 34 34 34 39 39 39 39 39 44 44 44 44 44 49 49 49 49 49 54 54 54 54 54 59 59 59 59 63 63 63 63 63 68 68 68 68 68 73
Drift:Expected Limit Delta:   x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -3 -3 2  2  2  -3 -3 2  2  2  -3 -3 2  2  2  -3 -3 2  2  2  -3 -3 2  2  -3 -3 2  2  2  -3 -3 2  2  2  -3
Drift:Preemptive Limit Delta: x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -1 -1 -1 -1 4  -1 -1 -1 -1 4  -1 -1 -1 -1 4  -1 -1 -1 -1 4  -1 -1 -1 -1 -1 -1 -1 -1 4  -1 -1 -1 -1 4  -1
Drift Edge Name:                                                                                               f2             r2             f3             r3             f4             r4         (f5)            r5             f6
Drift Clock (fake):           xxxxxxxxxxxxxxxxxxxxxx------------------------------------------------------------_______________---------------_______________---------------_______________------------_______________---------------___
Expected Edge Name:                                                                                                                 f3             r3             f4             r4             f5         (r5)            f6
Expected Clock:               xxxxxxxxxxxxxxxxxxxxxx---------------------------------------------------------------------------------_______________---------------_______________---------------____________---------------____________
Expected Half-Rate Limit:     x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 37 42 42 42 42 42 47 47 47 47 47 52 52 52 52 52 57 57 57 57 57 62 62 61 61 66 66 66 66 66 71 71 71 71
Preemptive Edge Name:                                                                                                      f3             r3             f4             r4             f5             r5         (f6)           r7
Preemptive Clock:             xxxxxxxxxxxxxxxxxxxxxx------------------------------------------------------------------------_______________---------------_______________---------------_______________------------_______________------
Preemptive Half-Rate Limit:   x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  34 34 34 34 34 34 34 34 34 34 34 34 34 34 39 39 39 39 39 44 44 44 44 44 49 49 49 49 49 54 54 54 54 54 59 59 59 59 59 63 63 63 63 68 68 68 68 68 73 73

! Insta-Sync Drift
? Mimic Not 50-50: Low Half-Rate 4(h), High Half-Rate 4(l), Starts at (s) = 10, Rx Delay (r) = 5, Tx Delay (t) = 6, Counter(c), Drift Window (w) = 1  -- hl indicates either High or Low rate
* Incoming - The clock signal from the pin after it has been properly syncronized and had events extracted
* Drift(d) - 
*          > Seed Drift by: [@f1] <= (c + h + l) - 1 ,,, Cycle 15 is the cycle that the edge is detected, add h and l, to get 19, subtract 1 since the edge was directly between the last and current cycle
*          > Update on Rising Edges: h - 1
*          > Update on Falling Edges: l - 1
* Expected(e) - Generated clock that mimics the cycle that the clock would have arrived directly at the Rx Pin
*             > Seed Expected by: [@f1]+1 <= (d + 2h + 2l) - r - 1*  [-1 is optional based on how the logic is done]
*             > Sync Delta on Rising Edge by: (r > hl) ? (hl - r) : ((h + l) - 2r)
* Premptive - Generated clock that triggers events earlier than the pin, to account for pipeline and sync latency
*           > Seed Preemptive by: [@f1]+1 <= (d + 2h + 2l) - r - t - 1*  [-1 is optional based on how the logic is done]
*           > Sync Delta on Rising Edge by: (r > hl) ? ((???????????????????) - r - t) : (hl - r - t)

Modulo Checks? (swap h and l for starting polarity low, example is starting polarity high)
 Clock Multiples | Expected Multiples | Preemptive Multiples
          h      | r ? 0 ?            |  : (r + t) ? 0 ?                
          h + l  | 0 : F(e)           |  : 0 ?
         2h + l  |                    |  : 0 ?
         2h + 2l |                    |  : 0 : F(p)
F(e) = (r > hl) ? 
F(p) = 

>NOTE: (r + w) <= (h + l) 
                                                                                                                        Seed Sync              Start Sync             Neg Drift
Incoming Edge Name:                                f0          r0          f1          r1          f2          r2         [f3]         r3         [f4]         r4      (f5)         r5          f6          r6          f7          r7
Incoming Clock:               xxxxxxx---------------____________------------____________------------____________------------____________------------____________---------____________------------____________------------____________---
Counter(c):                   0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
Drift High Half-Rate:         x x x x x x x x x x x  -  -  -  -  -  -  -  -  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4
Drift Low Half-Rate:          x x x x x x x x x x x  -  -  -  -  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4
Drift Event Upper Limit:      x x x x x x x x x x x  -  -  -  -  -  -  -  -  27 27 27 27 27 27 27 27 31 31 31 31 35 35 35 35 39 39 39 39 43 43 43 43 47 47 47 47 51 51 51 54 54 54 54 58 58 58 58 62 62 62 62 66 66 66 66 70 70 70 70 74
Drift Target:                 x x x x x x x x x x x  -  -  -  -  -  -  -  -  26 26 26 26 26 26 26 26 30 30 30 30 34 34 34 34 38 38 38 38 42 42 42 42 46 46 46 46 50 50 50 53 53 53 53 57 57 57 57 61 61 61 61 65 65 65 65 69 69 69 69 73
Drift Event Lower Limit:      x x x x x x x x x x x  -  -  -  -  -  -  -  -  25 25 25 25 25 25 25 25 29 29 29 29 33 33 33 33 37 37 37 37 41 41 41 41 45 45 45 45 49 49 49 52 52 52 52 56 56 56 56 60 60 60 60 64 64 64 64 68 68 68 68 72
Drift:Expected Limit Delta:   x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  3  -1 -1 -1 3  -1 -1 -1 3  -1 -1 -1 3  -1 -1 -1 3  -1 -1 -1 -1 -1 -1 3  -1 -1 -1 3  -1 -1 -1 3  -1 -1 -1 3  -1 -1 -1 3  -1
Drift:Preemptive Limit Delta: x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  1  -3 1  1  1  -3 1  1  1  -3 1  1  1  -3 1  1  1  -3 1  1  -3 1  1  1  -3 1  1  1  -3 1  1  1  -3 1  1  1  -3 1  1  1  -3
Drift Edge Name:                                                                                   f2          r2         [f3]         r3         [f4]         r4      (f5)         r5          f6          r6          f7          r7
Drift Clock (fake):           xxxxxxxxxxxxxxxxxxxxxx------------------------------------------------____________------------____________------------____________---------____________------------____________------------____________---
Expected Edge Name:                                                                                         f3          r3          f4          r4          f5          r5      (f6)         r6          f7          r7          f8
Expected Clock:               xxxxxxxxxxxxxxxxxxxxxx---------------------------------------------------------____________------------____________------------____________---------____________------------____________------------______
Expected Half-Rate Limit:     x x x x x x x x x x x  -  -  -  -  -  -  -  -  29 29 29 29 29 29 29 29 29 29 29 33 33 33 33 37 37 37 37 41 41 41 41 45 45 45 45 49 49 49 49 52 52 52 56 56 56 56 60 60 60 60 64 64 64 64 68 68 68 68 70 70
Preemptive Edge Name:                                                                     f3          r3          f4          r4          f5          r6          f7      (r7)         f8          r8          f9          r9
Preemptive Clock:             xxxxxxxxxxxxxxxxxxxxxx---------------------------------------____________------------____________------------____________------------_________------------____________------------____________------------
Preemptive Half-Rate Limit:   x x x x x x x x x x x  -  -  -  -  -  -  -  -  23 23 23 23 23 27 27 27 27 31 31 31 31 35 35 35 35 39 39 39 39 43 43 43 43 47 47 47 47 51 51 50 54 54 54 54 58 58 58 58 62 62 62 62 66 66 66 66 70 70 70 70

! Insta-Sync Drift
? Mimic Not 50-50: Low Half-Rate 3(h), High Half-Rate 4(l), Starts at (s) = 10, Rx Delay (r) = 5, Tx Delay (t) = 6, Counter(c), Drift Window (w) = 1  -- hl indicates either High or Low rate
* Incoming - The clock signal from the pin after it has been properly syncronized and had events extracted
* Drift(d) - 
*          > Seed Drift by: [@f1] <= (c + h + l) - 1 ,,, Cycle 15 is the cycle that the edge is detected, add h and l, to get 19, subtract 1 since the edge was directly between the last and current cycle
*          > Update on Rising Edges: h - 1
*          > Update on Falling Edges: l - 1
* Expected(e) - Generated clock that mimics the cycle that the clock would have arrived directly at the Rx Pin
*             > Seed Expected by: [@f1]+1 <= (d + 2h + 2l) - r - 1*  [-1 is optional based on how the logic is done]
*             > Sync Delta on Rising Edge by: (r > hl) ? (hl - r) : ((h + l) - 2r)
* Premptive - Generated clock that triggers events earlier than the pin, to account for pipeline and sync latency
*           > Seed Preemptive by: [@f1]+1 <= (d + 2h + 2l) - r - t - 1*  [-1 is optional based on how the logic is done]
*           > Sync Delta on Rising Edge by: (r > hl) ? ((???????????????????) - r - t) : (hl - r - t)

Modulo Checks? (swap h and l for starting polarity low, example is starting polarity high)
 Clock Multiples | Expected Multiples | Preemptive Multiples
          h      | r ? 0 ?            |  : (r + t) ? 0 ?                
          h + l  | 0 : F(e)           |  : 0 ?
         2h + l  |                    |  : 0 ?
         2h + 2l |                    |  : 0 : F(p)
F(e) = (r > hl) ? 
F(p) = 

! The below only need to be recalculated if h, l, r, or t change
? Expected Delta
Rising Edge and Falling Edge use same equation, they will always have same delta directly before an edge
(r > hl) ? ((2l + 2h) - ((l + h) - r)) : //! Need to check when r is between h and l
? Preemptive Delta
((r + t) > (h + l)) ? ((3l + 3h) - ((l + h) - (r + t)) : //! This has 4 possible conditions 0, 1, 2, or 3 edges early...


>NOTE: (r + w) <= (h + l) 
                                                                                                               Seed Sync           Start Sync          Neg Drift
Incoming Edge Name:                                f0       r0          f1       r1          f2       r2         [f3]      r3         [f4]       r4     (f5)      r5          f6       r6          f7       r7          f8       r8
Incoming Clock:               xxxxxxx---------------_________------------_________------------_________------------_________------------_________---------_________------------_________------------_________------------_________------
Counter(c):                   0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70
Drift High Half-Rate:         x x x x x x x x x x x  -  -  -  -  -  -  -  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4
Drift Low Half-Rate:          x x x x x x x x x x x  -  -  -  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3  3
Drift Event Upper Limit:      x x x x x x x x x x x  -  -  -  -  -  -  -  25 25 25 25 25 25 25 28 28 28 32 32 32 32 35 35 35 39 39 39 39 42 42 42 46 46 46 48 48 48 52 52 52 52 55 55 55 59 59 59 59 62 62 62 66 66 66 66 69 69 69 72 72
Drift Target:                 x x x x x x x x x x x  -  -  -  -  -  -  -  24 24 24 24 24 24 24 27 27 27 31 31 31 31 34 34 34 38 38 38 38 41 41 41 45 45 45 47 47 47 51 51 51 51 54 54 54 58 58 58 58 61 61 61 65 65 65 65 68 68 68 71 71
Drift Event Lower Limit:      x x x x x x x x x x x  -  -  -  -  -  -  -  23 23 23 23 23 23 23 26 26 26 30 30 30 30 33 33 33 37 37 37 37 40 40 40 44 44 44 46 46 46 50 50 50 50 53 53 53 57 57 57 57 60 60 60 64 64 64 64 67 67 67 70 70
Drift:Expected Limit Delta:   x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  -  -  -  2  -1 -1 2  -2 -2 2  2  -1 -1 2  -2 -2 2  2  -1 -1 2  -2 -2 2  -2 -2 2  2  -1 -1 2  -2 -2 2  2  -1 -1 2  -2 -2 2  2  -1 -1 2  -2 -2 2  2  -1
Drift:Preemptive Limit Delta: x x x x x x x x x x x  -  -  -  -  -  -  -  -  -  -  -  -  -  -  0  0  0  -1 -1 -1 3  0  0  0  -1 -1 -1 3  0  0  0  -1 -1 -1 3  0  0  0  -1 -1 -1 3  0  0  0  -1 -1 -1 3  0  0  0  -1 -1 -1 3  0  0  0  -1
Drift Edge Name:                                                                             f2       r2         [f3]      r3         [f4]       r4     (f5)      r5          f6       r6          f7       r7          f8       r8
Drift Clock (fake):           xxxxxxxxxxxxxxxxxxxxxx------------------------------------------_________------------_________------------_________---------_________------------_________------------_________------------_________------
Expected Edge Name:                                                                                f3       r3          f4       r4          f5       r6
Expected Clock:               xxxxxxxxxxxxxxxxxxxxxx------------------------------------------------_________------------_________------------_________---
Expected Half-Rate Limit:     x x x x x x x x x x x  -  -  -  -  -  -  -  26 26 26 26 26 26 26 26 26 29 29 29 33 33 33 33 36 36 36 40 40 40 40 43 43 43 47
Preemptive Edge Name:                                                            f3       r3          f4       r4          f5       r6          f7
Preemptive Clock:             xxxxxxxxxxxxxxxxxxxxxx------------------------------_________------------_________------------_________------------_________
Preemptive Half-Rate Limit:   x x x x x x x x x x x  -  -  -  -  -  -  -  20 20 20 23 23 23 27 27 27 27 30 30 30 34 34 34 34 37 37 37 41 41 41 41 44 44 44

*/

module preemptive_clock (
    input                 common_p::clk_dom_s sys_dom_i,
    input  
);



endmodule : preemptive_clock
