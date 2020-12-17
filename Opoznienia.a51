;-----------------------------------------------------------------
; Kilka sposobow na realizacje opoznien w 8051
; by Gorka Mateusz
;-----------------------------------------------------------------
LEDS    EQU     P1                      ; diody LED na P1 (0=ON)
;-----------------------------------------------------------------
TIME_MS EQU     50                      ; czas w [ms]
CYCLES  EQU     (1000 * TIME_MS)        ; czas w cyklach (f = 12 MHz)
LOAD    EQU     (65536 - CYCLES)        ; wartosc ladowana do TH0|TL0
;-----------------------------------------------------------------
CNT_50  EQU     30h                     ; licznik w ramach sekundy
SEC     EQU     33h                     ; sekundy
MIN     EQU     32h                     ; minuty
HOUR    EQU     31h                     ; godziny

;-----------------------------------------------------------------
; Zapala co 50ms kolejna diode.
;-----------------------------------------------------------------
ORG 0
        lcall   init_clock
        mov     LEDS,   #0feh           ; zapalenie 1 diody

leds_loop:
        mov     a,      LEDS            ; przesuniecie diody
        rl      a                       ; ...
        mov     LEDS,   a               ; ...
        lcall   delay_timer_50ms        ; Opoznienie o 50ms
        lcall   update_time             ; Aktualizacja czasu

        sjmp    leds_loop


;---------------------------------------------------------------------
; Inicjalizuje timer0
; TMOD:
;       GATE    - 0
;       C/T     - 0     - timer
;       M1      - 0     }
;       M0      - 1     } - tryb 16-bitowy
;---------------------------------------------------------------------
init_clock:
        anl     TMOD,   #0f0h           ; Konfiguracja Timer0: #0001b (czyscimy)
        orl     TMOD,   #001h           ; ... (nadpisujemy)

        mov     CNT_50, #20             ; Licznik dla procedury update_time
        mov     SEC,    #55             ; Wartosci poczatkowe dla liczenia
        mov     MIN,    #58
        mov     HOUR,   #23

        ret


;---------------------------------------------------------------------
; Opoznienie 50 ms (zegar 12 MHz)
; 50ms = 50 000 us = 500us * 100
;---------------------------------------------------------------------
delay_50ms:
        mov     R1,     #100            ;                      1
_50ms_loop:
        nop                             ; 1 x 100       =    100
        mov     R2,     #248            ; 1 x 100       =    100
        djnz    R2,     $               ; 2 x 100 x 248 = 49 600
        djnz    R1,     _50ms_loop      ; 2 x 100       =    200
        ret                             ;              + ______2______
                                        ;                 50 003 cykli


;---------------------------------------------------------------------
; Opoznienie n * 50 ms (zegar 12 MHz)
; R7 - n, czas x 50 ms
;---------------------------------------------------------------------
delay_nx50ms:
        mov     R6,     #100             ; 1 x N         =      1N
n_50ms_loop:
        mov     R5,     #248             ; 1 x N x 100   =    100N
        nop                              ; 1 x N x 100   =    100N
        djnz    R5,     $                ; 2 x N x 100x248=49 600N
        djnz    R6,     n_50ms_loop      ; 2 x N x 100   =    200N
        djnz    R7,     delay_nx50ms     ; 2 x N         =      2N
        ret                              ; 2           + _______2_____
                                         ;                 50 003N + 2


;---------------------------------------------------------------------
; Opoznienie 50 ms z uzyciem Timera 0 (zegar 12 MHz)
delay_timer_50ms:
        mov     TL0,    #low(load)
        mov     TH0,    #high(load)
        setb    TR0
        jnb     TF0,    $
        clr     TR0
        clr     TF0

        ret


;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | CNT_50
; Przy wywolywaniu procedury co 50 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;
; Co ile wywolan?| Ile cykli?
;       1        |  4 cykle
;      20        |  9 cykli
;     120        | 14 cykli
;   72000        | 19 cykli
; 1728000        | 20 cykli
;---------------------------------------------------------------------
update_time:
        djnz    CNT_50, no_change               ; licznik (co 20)
        mov     CNT_50, #20
        inc     SEC                             ; Aktualizacja sekund
        mov     A,      SEC
        cjne    A,      #60,    no_change
        mov     SEC,    #0                      ; Aktualizacja minut
        inc     MIN
        mov     A,      MIN
        cjne    A,      #60,    no_change
        mov     MIN,    #0                      ; Aktualizacja godzin
        inc     HOUR
        mov     A,      HOUR
        cjne    A,      #24,    no_change
        mov     HOUR,   #0                      ; Koniec doby
no_change:
        ret

END