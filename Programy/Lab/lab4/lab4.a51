WR_CMD		EQU	0FF2Ch		; zapis rejestru komend
WR_DATA		EQU	0FF2Dh		; zapis rejestru danych
RD_STAT		EQU	0FF2Eh		; odczyt rejestru statusu
RD_DATA		EQU	0FF2Fh		; odczyt rejestru danych

ORG 0

	lcall	lcd_init		; inicjowanie wyswietlacza

	mov	A, #04h				; x = 4, y = 0
	lcall	lcd_gotoxy		; przejscie do pozycji (4, 0)

	mov	DPTR, #text_hello	; wyswietlenie tekstu
	lcall	lcd_puts

	mov	A, #14h				; x = 4, y = 1
	lcall	lcd_gotoxy		; przejscie do pozycji (4, 1)

	mov	DPTR, #text_number	; wyswietlenie tekstu
	lcall	lcd_puts

	mov	A, #12				; wyswietlenie liczby
	lcall	lcd_dec_2

	sjmp	$

;=====================================================================

;---------------------------------------------------------------------
; Zapis komendy
;
; Wejscie: A - kod komendy
;---------------------------------------------------------------------
lcd_write_cmd:
	push DPH
	push DPL

	push ACC					; zapisuje komende na stosie
	mov DPTR, #RD_STAT
	
wait_till_busy_cmd:				; czekam, az sterownik bedzie dostepny
	movx A, @DPTR
	jb ACC.7, wait_till_busy_cmd
	
	pop ACC						; wprowadzam komende
	mov DPTR, #WR_CMD
	movx @DPTR, A
	
	pop DPL
	pop DPH
	ret

;---------------------------------------------------------------------
; Zapis danych
;
; Wejscie: A - dane do zapisu
;---------------------------------------------------------------------
lcd_write_data:
	push DPH
	push DPL

	push ACC					; zapisuje dane na stosie
	mov DPTR, #RD_STAT
	
wait_till_busy_data:			; czekam, az sterownik bedzie dostepny
	movx A, @DPTR
	jb ACC.7, wait_till_busy_data
	
	pop ACC						; wprowadzam dane
	mov DPTR, #WR_DATA
	movx @DPTR, A
	
	pop DPL
	pop DPH
	ret

;---------------------------------------------------------------------
; Inicjowanie wyswietlacza
;---------------------------------------------------------------------
lcd_init:
	
	mov A, #00111000b			; ustalenie tryby pracy
	lcall lcd_write_cmd
	
	mov A, #00000110b			; ustalenie trybu wprowadzania
	lcall lcd_write_cmd
	
	mov A, #00001111b			; kontrola widocznosci elementu lcd
	lcall lcd_write_cmd
	
	mov A, #00000001b			; wyczyszczenie ekranu
	lcall lcd_write_cmd

	ret

;---------------------------------------------------------------------
; Ustawienie biezacej pozycji wyswietlania
;
; Wejscie: A - pozycja na wyswietlaczu: ---y | xxxx
;---------------------------------------------------------------------
lcd_gotoxy:

	jnb ACC.4, call_command		; sprawdzam, czy potrzebna jest korekta
	
	clr ACC.4					; korekta
	setb ACC.6
	
call_command:
	setb ACC.7					; dopelniam brrakujacy bit komendy
	lcall lcd_write_cmd

	ret

;---------------------------------------------------------------------
; Wyswietlenie tekstu od biezacej pozycji
;
; Wejscie: DPTR - adres pierwszego znaku tekstu w pamieci kodu
;---------------------------------------------------------------------
lcd_puts:
	
next_char:					; wyswietlam kolejne bajty w formie kodow ascii
	clr A
	movc A, @A+DPTR
	jz stop_printing
	lcall lcd_write_data
	inc DPTR
	sjmp next_char

stop_printing:
	ret

;---------------------------------------------------------------------
; Wyswietlenie liczby dziesietnej
;
; Wejscie: A - liczba do wyswietlenia (00 ... 99)
;---------------------------------------------------------------------
lcd_dec_2:
	
	mov B, #10				; dzielenie przez 10
	div AB
	
	add A, #'0'				; wyswietlenie starszej cyfry
	lcall lcd_write_data
	
	mov A, B				; wyswietlenie mlodszej cyfry
	add A, #'0'
	lcall lcd_write_data
	
	ret

;---------------------------------------------------------------------
; Definiowanie wlasnego znaku
;
; Wejscie: A    - kod znaku (0 ... 7)
;          DPTR	- adres tabeli opisu znaku w pamieci kodu
;---------------------------------------------------------------------
lcd_def_char:

	setb ACC.6				; przeslanie komendy ustalenia adresu CGRAM
	clr ACC.7
	lcall lcd_write_cmd
	
	mov A, #8

write_next_byte:			; zapis znaku do CGRAM
	jz stop_writing
	push ACC
	clr A
	movc A, @A+DPTR
	lcall lcd_write_data
	inc DPTR
	pop ACC
	dec A
	sjmp write_next_byte

stop_writing:				; ustalenie adresu w DDRAM
	mov A, #10000000b
	lcall lcd_write_cmd

	ret

;=====================================================================

my_char_0: db 1Fh, 11h, 11h, 11h, 11h, 11h, 11h, 1Fh

text_hello:
	db	'Hello word', 0
text_number:
	db	'Number = ', 0

END