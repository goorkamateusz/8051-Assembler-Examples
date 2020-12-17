;---------------------------------------------------------------------
; Wypelnianie, odwracanie tabclie w IRAM i XRAM
; by Gorka Mateusz
;---------------------------------------------------------------------
ORG 0

test_reverse_iram:
        mov     R0, #30h        ; address poczatkowy tablicy
        mov     R2, #8          ; dlugosc tablicy
        lcall   fill_iram

        mov     R0, #30h        ; address poczatkowy tablicy
        mov     R2, #8          ; dlugosc tablicy
        lcall   reverse_iram

test_reverse_xram:
        mov     DPTR, #8000h    ; address poczatkowy tablicy
        mov     R2, #81h        ; dlugosc tablicy R3|R2
        mov     R3, #1h
        lcall   fill_xram

        mov     DPTR, #8000h    ; address poczatkowy tablicy
        mov     R2, #81h        ; dlugosc tablicy R3|R2
        mov     R3, #1h
        lcall   reverse_xram

test_string:
        mov     DPTR, #text     ; address poczatkowy stringu (CODE)
        mov     R0, #30h        ; address poczatkowy stringu (IRAM)
        lcall   copy_string

        mov     DPTR, #text     ; address poczatkowy stringu (CODE)
        mov     R0, #30h        ; address poczatkowy stringu (IRAM)
        lcall   reverse_string

        mov     DPTR, #text     ; address poczatkowy stringu (CODE)
        mov     R0, #30h        ; address poczatkowy stringu (IRAM)
        lcall   count_letters

        sjmp    $

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (IRAM)
; Input:  R0 - address poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_iram:
        mov     A,      #1              ; wartosc poczatkowa
fill_iram_loop:
        mov     @R0,    A               ; zapis
        inc     R0
        inc     A
        djnz    R2,     fill_iram_loop
        
        ret

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (XRAM)
; Input:  DPTR  - address poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_xram:
        mov     R0,     #1              ; wartosc poczatkowa
fill_xram_loop:
        mov     A,      R0
        movx    @DPTR,  A               ; zapis
        inc     DPTR
        inc     R0
        
        cjne    R2,     #0, fx_no       ; dekrementacja R3|R2
        dec     R3
fx_no:  dec     R2
        
        mov     A,      R3              ; Jesli R3|R2 == 0
        orl     A,      R2              ; to powtorz
        jnz     fill_xram_loop          ;;

        ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci wewnetrznej (IRAM)
; Input:  R0 - address poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_iram:
        mov     A,      R0              ; Wyliczenie addressu konca
        add     A,      R2              ;;
        dec     A                       ;;
        mov     R1,     A               ;; R1 - address konca tablicy
        
        mov     A,      R2              ; Wyliczenie polowy dlugosci tablicy
        clr     C                       ;;
        rrc     A                       ;;
        mov     R2,     A               ;;
        
reverse_iram_loop:
        mov     A,      @R0             ; zamienia @R1 <-> @R2
        xch     A,      @R1             ; ...
        mov     @R0,    A               ; ...

        inc     R0                      ; ++R0 (poczatek)
        dec     R1                      ; --R1 (koniec)
        djnz    R2,     reverse_iram_loop

        ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci zewnetrznej (XRAM)
; Input:  DPTR  - address poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_xram:
        ;-------------------------------; Wyliczyc koniec tablicy R1|R0
        mov     A,      DPL             ; R2+DPL-1
        add     A,      R2              ;;
        jnz     rx_no0
        clr     C
rx_no0: dec     A                       ;;
        mov     R0,     A               ; LOW
        mov     A,      DPH             ; R3+DPH
        addc    A,      R3              ;;
        mov     R1,     A               ; HIGH

        ;-------------------------------; Wyliczenie polowy tablicy
        mov     A,      R3              ; HIGH /= 2
        clr     C                       ;;
        rrc     A                       ;;              
        mov     R3,     A               ;;
        mov     A,      R2              ; LOW = LOW/2 + przesuniecie
        rrc     A                       ;;
        mov     R2,     A               ;;

        ;-------------------------------; Obracanie XRAM                                
rx_loop:
        movx    A,      @DPTR           ; pobiera z poczatku
        mov     B,      A               
        mov     R7,     DPH             
        mov     R6,     DPL
        mov     DPH,    R1              ; pobiera z konca
        mov     DPL,    R0              ;
        movx    A,      @DPTR           ; <-
        xch     A,      B               ; wrzuca na koniec
        movx    @DPTR,  A               ; <-
        mov     DPH,    R7              ; wrzuca na porzatek
        mov     DPL,    R6              ;
        mov     A,      B               ;
        movx    @DPTR,  A               ; <-
        
        inc     DPTR                    ; ++przod
        
        cjne    R0,     #0, rx_no2      ; --tyl, dekr R1|R0
        dec     R1                      ;;
rx_no2: dec     R0                      ;;
        
        cjne    R2,     #0, rx_no3      ; --licznik, dekr R3|R2
        dec     R3                      ;;
rx_no3: dec     R2                      ;;
        
        mov     A,      R3              ; Jesli R3|R2 != 0
        orl     A,      R2              ; to powtorz
        jnz     rx_loop                 ;;

        ret

;---------------------------------------------------------------------
; Kopiowanie stringu z pamieci programu (CODE) do pamieci IRAM
; Input:  DPTR - address poczatkowy stringu (CODE)
;           R0   - address poczatkowy stringu (IRAM)
;---------------------------------------------------------------------
copy_string:
        
cs_loop:
        clr     A
        movc    A,      @A+DPTR         ; poranie znaku
        mov     @R0,    A               ; skopiowanie znaku
        inc     R0
        inc     DPTR
        
        jnz     cs_loop                 ; dopuki znak rozny od 0 
        
        ret

;---------------------------------------------------------------------
; Odwracanie stringu w pamieci IRAM
; Input:  R0 - address poczatkowy stringu
;---------------------------------------------------------------------
reverse_string:
        mov     R2,     #0              ; licznik znaku
        mov     A,      R0
        mov     R1,     A               ; tymczasowy poczatek stringu
        
count_txt_loop:
        mov     A,      @R1             ; pobiera znak
        inc     R1
        inc     R2
        jnz     count_txt_loop          ; sprawdza czy znak != 0
        
        dec     R2
        
        lcall   reverse_iram            ; obraca
        
        ret

;---------------------------------------------------------------------
; Zliczanie liter w stringu umieszczonym w pamieci IRAM
; Input:  R0 - address poczatkowy stringu
; Output:  A  - liczba liter w stringu
;---------------------------------------------------------------------
count_letters:
        clr     A                       ; licznik liter
        
count_loop:
        cjne    @R0,    #0,     not_0   ; jesli rozny
        jmp     ct_end                  ; KONIEC zliczania
        
not_0:  cjne    @R0,    #'A',   neq_AA  ; 
neq_AA: jc      not_letter              ; skok skok znak < 'A'
        
        cjne    @R0,    #'Z'+1, neq_ZZ  ; 
neq_ZZ: jc      letter                  ; skok jesli znak < 'Z'+1
        
        cjne    @R0,    #'a',   neq_a   ;
neq_a:  jc      not_letter              ; skok jesli znak < 'a'
        
        cjne    @R0,    #'z'+1, neq_z
neq_z:  jnc     not_letter              ; skok jesli znak >= 'z'+1

letter: inc     A                       ; znaleziono

not_letter:
        inc     R0                      ; sprawdz nastepny znak
        jmp     count_loop              ;;
        
ct_end: ret
        
        
        
;---------------------------------------------------------------------
text:   DB      'Hello World 0123456789', 0

END