;---------------------------------------------------------------------
; By Gorka Mateusz
;---------------------------------------------------------------------
P5              EQU     0F8h            ; adres P5 w obszarze SFR
P7              EQU     0DBh            ; adres P7 w obszarze SFR
;---------------------------------------------------------------------
ROWS            EQU     P5              ; wiersze na P5.7-4
COLS            EQU     P7              ; kolumny na P7.3-0
;---------------------------------------------------------------------
LEDS            EQU     P1              ; diody LED na P1 (0=ON)
;---------------------------------------------------------------------

ORG 0
        mov     SP,     #31h            ; ustawienie adresu stosu
        mov     LEDS,   #0ffh

main_loop:      
        lcall   kbd_read
        lcall   kbd_display
        sjmp    main_loop

;---------------------------------------------------------------------
; Uaktywnienie wybranego wiersza klawiatury
;
; Wejscie: A - numer wiersza (0 .. 3)
;---------------------------------------------------------------------
kbd_select_row:
        orl     ROWS,   #11110000b
        cjne    A,      #4,     equalR  ; jesli A < 4
equalR: jc      set_row                 ;;
        ret
set_row:
        mov     DPTR,   #KEY_CODE       ; konwertuje wartosc na kod
        movc    A,      @A+DPTR         ;;
        anl     ROWS,   A               ;;
        ret

;---------------------------------------------------------------------
; Odczyt wybranego wiersza klawiatury
;
; Wejscie: A  - numer wiersza (0 .. 3)
; Wyjscie: CY - stan wiersza (0 - brak klawisza, 1 - wcisniety klawisz)
;          A  - kod klawisza (0 .. 3)
;---------------------------------------------------------------------
kbd_read_row:   
        lcall   kbd_select_row          ; ustaw wiersz A
        
        mov     A,      COLS            ; sprawdza czy ktory kolwiek klawisz
        orl     A,      #11110000b      ; jest wcisniety
        cpl     A                       ;;
        jz      row_not_found           ;;

        mov     R1,     #0              ; licznik klawisza (w kolumnie)
        mov     A,      #00001000b      ; maska odczytu
        
read_row_loop:
        push    ACC
        anl     A,      COLS            ; sprawdz klawisz
        jz      row_found               ; jesli znaleziono
        pop     ACC
        rr      A                       ; przesun maske
        anl     A,      #00001111b      ;;
        inc     R1                      ; sprawdz nastepny klawisz
        jnz     read_row_loop           ;;
row_not_found:
        clr     C
        ret 
        
row_found:
        pop     ACC
        mov     A,      R1              ; A <- numer klawisza
        setb    C
        ret

;---------------------------------------------------------------------
; Odczyt calej klawiatury
;
; Wyjscie: CY - stan klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
;          A - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_read:
        mov     R0,     #0              ; numer wiersza

read_loop:
        mov     A,      R0              ; sprawdza wiersz
        lcall   kbd_read_row            ;;
        jc      read_found              ; jesli znaleziono

        inc     R0                      ; nastepny wiersz
        cjne    R0,     #4,     equal   ; jesli R0<4
equal:  jc      read_loop               ;;
        
        clr     C
        jmp     read_end
        
read_found:
        mov     R1,     A               ; nr kolumny
        mov     A,      R0              ; nr wiersza x 4
        rl      A                       ;; 
        rl      A                       ;;
        add     A,      R1              ; rows x 4 + cols
        setb    C                       
        
read_end:
        ret

;---------------------------------------------------------------------
; Wyswietlenie stanu klawiatury
;
; Wejscie: CY - stanu klawiatur (0 - brak klawisza, 1 - wcisniety klawisz)
;          A  - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_display:
        jc      light                   ; jesli CY = 1 to zapal
        mov     LEDS,   #0ffh           ; zgas wszystkieg
        jmp     display_end
        
light:  cpl     A                       ; negacja
        clr     ACC.7
        mov     LEDS,   A               ; zapalenie diod
        
display_end:
        ret
        
;----------------------------------------------------------------------
; Kody wierzy
;----------------------------------------------------------------------
KEY_CODE:
        DB      01111111B       ; 0
        DB      10111111B       ; 1
        DB      11011111B       ; 2
        DB      11101111B       ; 3     

END