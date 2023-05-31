;---------------------------------------------------------------------
P5		EQU	0F8h		; adres P5 w obszarze SFR
P7		EQU	0DBh		; adres P7 w obszarze SFR
;---------------------------------------------------------------------
ROWS		EQU	P5		; wiersze na P5.7-4
COLS		EQU	P7		; kolumny na P7.3-0
;---------------------------------------------------------------------
LEDS		EQU	P1		; diody LED na P1 (0=ON)
;---------------------------------------------------------------------
ALL_ROWS_OFF	EQU 11110000b


ORG 0

main_loop:
	lcall kbd_read_row
	sjmp	main_loop

	lcall	kbd_read
	lcall	kbd_display
	sjmp	main_loop

;---------------------------------------------------------------------
; Uaktywnienie wybranego wiersza klawiatury
;
; Wejscie: A - numer wiersza (0 .. 3)
;---------------------------------------------------------------------
kbd_select_row:
	
	; Sprawdzam czy zadano wartosc != 3, 
	; Jezeli nie, to ustawiam bit odpowiadajacy wartosci 3 i wychodze z procedury
	cjne A, #3, not_eq_three
	clr P5.4
	sjmp row_selected
	
	; Sprawdzam czy zadano wartosc <3 lub >3
	; Jezeli >3 to wylaczam wszystkie wiersze i wychodze z procedury
not_eq_three:
	jc less_than_three
	orl P5, #ALL_ROWS_OFF
	sjmp row_selected

	; Sprawdzam czy zadano wartosc != 2
	; Jezeli nie, to ustawiam bit odpowiadajacy wartosci 2 i wychodze z procedury
less_than_three:
	cjne A, #2, less_than_two
	clr P5.5
	sjmp row_selected

	; Sprawdzam, czy zadano wartosc !=1
	; Jezeli nie, to ustawiam bit odpowiadajacy wartosci 1 i wychodze z procedury
less_than_two:
	cjne A, #1, equal_to_zero
	clr P5.6
	sjmp row_selected

	; W tej sytuacji jedyna wartoscia do rozwazenia pozostalo 0
equal_to_zero:
	clr P5.7

row_selected:
	ret

;---------------------------------------------------------------------
; Odczyt wybranego wiersza klawiatury
;
; Wejscie: A  - numer wiersza (0 .. 3)
; Wyjscie: CY - stan wiersza (0 - brak klawisza, 1 - wcisniety klawisz)
;	   A  - kod klawisza (0 .. 3)
;---------------------------------------------------------------------
kbd_read_row:
	
	; Wybranie wiersza
	lcall kbd_select_row
	
	; Wyzerowanie carry
	clr c
	
	; Sprawdzam czy wcisniety jest pierwszy klawisz z lewej
	; Jezeli jest, to zwracam 0 i ustawaiam C w stan wysoki
	jb P7.3, check_second_key
	mov A, #0
	sjmp key_is_pressed
	
	; Sprawdzam, czy wcisniety jest drugi klawisz z lewej
	; Jezeli jest, to zwracam 1 i ustawiam C w stan wysoki
check_second_key:
	jb P7.2, check_third_key
	mov A, #1
	sjmp key_is_pressed
	
	; Sprawdzam, czy wcisniety jest trzeci klawisz z lewej
	; Jezeli jest, to zwracam 2 i ustawiam C w stan wysoki
check_third_key:
	jb P7.1, check_fourth_key
	mov A, #2
	sjmp key_is_pressed
	
	; Sprawdzam, czy wcisniety jest czwarty klawisz z lewej
	; Jezeli jest to zwracam 3 i ustawiam C w stan wysoki
	; Jezeli nie jest, to zaden z klawiszy nie jest wcisniety
check_fourth_key:
	jb P7.0, key_is_not_pressed
	mov A, #3
	sjmp key_is_pressed
	
key_is_pressed:
	setb c

key_is_not_pressed:
	ret

;---------------------------------------------------------------------
; Odczyt calej klawiatury
;
; Wyjscie: CY - stan klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_read:

	ret

;---------------------------------------------------------------------
; Wyswietlenie stanu klawiatury
;
; Wejscie: CY - stanu klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A  - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_display:

	ret

END