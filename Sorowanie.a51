;---------------------------------------------------------------------
; Gorka Mateusz - 
;---------------------------------------------------------------------
ORG 0
        mov     DPTR, #test_data        ; adres poczatkowy danych
        mov     R0, #30h                ; adres poczatkowy tablicy
        lcall   copy_data

        mov     R0, #30h                ; adres poczatkowy tablicy
        mov     R2, #11                 ; dlugosc tablicy
        lcall   bubble_sort_iram

        sjmp    $

;---------------------------------------------------------------------
; Kopiowanie danych z pamieci programu (CODE) do pamieci IRAM
; Dane CODE: pierwszy bajt - licznik danych, kolejne bajty  - dane
; Wejscie:  DPTR - adres poczatkowy bloku danych (CODE)
;           R0   - adres poczatkowy (IRAM)
;---------------------------------------------------------------------
copy_data:
        clr     A                       ;; R1 - dlugosc
        movc    A,      @A+DPTR         ;;
        jz      no_copy                 ; jesli zerwoa dlugosc: wyjdz
        mov     R1,     A               ;;
        
cp_loop:
        inc     DPTR                    ; ++code
        clr     A                       ; kopiowanie
        movc    A,      @A+DPTR         ;;
        mov     @R0,    A               ;;
        inc     R0                      ; ++ iram
        djnz    R1,     cp_loop         ; petla
no_copy:
        ret

;---------------------------------------------------------------------
; Sortowanie babelkowe (rosnaco) w pamieci wewnetrznej (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
; bubblesort:
;   do
;     swapped <- false
;     for j = 0 to size-1 do:
;        if arr[i] > arr[i+1]
;           swap arr[j], arr[j+1]
;           swapped <- true
;        end if
;     end for
;     size--
;   while swapped = false
; end
;---------------------------------------------------------------------
bubble_sort_iram:
        cjne    R2,     #2,     neq0    ; Wyjatek: dlugosc < 2
neq0:   jc      no_sort                 ;;

        dec     R2                      ; dlugosc-1

bbbl_loop:
        clr     F0                      ; swapped = false
        mov     A,      R2              ; R3 - tymczasowa dlugosc-1
        mov     R3,     A               ;;
        mov     A,      R0              ; R1 - tymczasowy adres elem.
        mov     R1,     A               ;;
        
swap_loop:
        mov     A,      @R1             ; pobranie danych
        inc     R1                      ;;
        mov     B,      @R1             ;;
        
        cjne    A,      B,      neq1    ; 
        jmp     no_swap                 ; arr[i] = arr[i+1]
neq1:   jc      no_swap                 ; arr[i] < arr[i+1]
        mov     @R1,    A               ; zamiana
        dec     R1                      ;;
        mov     @R1,    B               ;;
        inc     R1                      ;;
        setb    F0                      ; swapped = true
no_swap:
        djnz    R3,     swap_loop       ; petla swap
        dec     R2                      ; dlugosc-- (ostatni element jest juz posortowany)
        
        jb      F0,     bbbl_loop       ; patla bbbl
        
no_sort:
        ret


;---------------------------------------------------------------------
test_data:
        DB      11
        DB      6, 5, 3, 7, 4, 2, 0, 1, 9, 8, 4

END