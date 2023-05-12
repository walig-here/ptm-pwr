;------------------------------------------------------------------------------
TIME_MS		EQU	50					; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
CNT_50		EQU	30h			; licznik w ramach sekundy
SEC			EQU	31h			; sekundy
MIN			EQU	32h			; minuty
HOUR		EQU	33h			; godziny

ALARM_SEC	EQU	34h			; alarm - sekundy
ALARM_MIN	EQU	35h			; alarm - minuty
ALARM_HOUR	EQU	36h			; alarm - godziny
	
SEC_SINCE_LAST_ALARM EQU 37h	; liczba sekund od ostatniego alarmu
ALARM_DURATION EQU 38h			; czas trwania alarmu w sekundach

SEC_CHANGE	EQU	0			; flaga zmiany sekund (BIT)
;------------------------------------------------------------------------------
LEDS		EQU	P1			; diody LED na P1 (0=ON)
ALARM		EQU	P1.7		; sygnalizacja alarmu
;------------------------------------------------------------------------------
WR_CMD		EQU	0FF2Ch		; zapis rejestru komend
WR_DATA		EQU	0FF2Dh		; zapis rejestru danych
RD_STAT		EQU	0FF2Eh		; odczyt rejestru statusu
RD_DATA		EQU	0FF2Fh		; odczyt rejestru danych
;------------------------------------------------------------------------------

CSEG AT 0
	sjmp	start
	
CSEG AT 0Bh
;---------------------------------------------------------------------
; Obsluga przerwania Timera 0
;---------------------------------------------------------------------
T0_int:
	mov TL0, #LOW(LOAD)
	mov TL1, #HIGH(LOAD)
	
	push ACC
	
	dec CNT_50				; aktualizacja licznika 50ms
	mov A, CNT_50
	jnz end_timer_int
	mov CNT_50, A
		
	inc SEC					; aktualizacja licznika sekund oraz obsluga alarmu
	setb SEC_CHANGE
	mov A, SEC
	xrl A, #60
	jnz end_timer_int
	mov SEC, A
	
	inc MIN					; aktualizacja licznika minut
	mov A, MIN
	xrl A, #60
	jnz end_timer_int
	mov MIN, A
	
	inc HOUR				; aktualizacja godzin
	mov A, HOUR
	xrl HOUR, #24
	jnz end_timer_int
	mov HOUR, A

end_timer_int:
	pop ACC
	reti

;---------------------------------------------------------------------
; Start programu
;---------------------------------------------------------------------
start:
	lcall clock_init
	lcall timer_init
	lcall main_loop

;---------------------------------------------------------------------
; Petla glowna programu
;---------------------------------------------------------------------
main_loop:
	jnb SEC_CHANGE, main_loop	; czekam na zmiane sekundy
	clr SEC_CHANGE
	
	lcall clock_display
	lcall clock_alarm
	
	sjmp	main_loop

;---------------------------------------------------------------------
; Inicjowanie Timera 0 w trybie 16-bitowym z przerwaniami
;---------------------------------------------------------------------
timer_init:
	clr TR0					; zatrzymanie Timer 0
	
	mov A, #00001001b		; konfiguracja Timer 0
	orl TMOD, A
	
	mov TL0, #LOW(LOAD)		; ustawienie czasu na Timer 0
	mov TH0, #HIGH(LOAD)
	
	clr TF0					; wyzerowanie flagi przepelnienia Timer 0
	
	setb ET0				; wlaczenie przerwan
	setb EA
	
	setb TR0				; wlaczenie timera
	
	ret

;---------------------------------------------------------------------
; Inicjowanie zmiennych zwiazanych z czasem
;---------------------------------------------------------------------
clock_init:
	mov CNT_50, #0			; ustawienie czasu poczatkowego
	mov SEC, #45
	mov MIN, #59
	mov HOUR, #23
	
	mov ALARM_SEC, #0		; ustawienie czasu alarmu
	mov ALARM_MIN, #0
	mov ALARM_HOUR, #0
	
	mov SEC_SINCE_LAST_ALARM, #0
	mov ALARM_DURATION, #2
	
	ret

;---------------------------------------------------------------------
; Wyswietlanie czasu
;---------------------------------------------------------------------
clock_display:
	
	mov A, #03				; ustawienie kursora
	lcall lcd_gotoxy
	
	mov A, HOUR				; wyswietlenie godziny
	lcall lcd_dec_2
	
	mov A, #':'				; wysweitlenie dwukropka
	lcall lcd_write_data
	
	mov A, MIN				; wyswietlenie minuty
	lcall lcd_dec_2
	
	mov A, SEC				; wyswietlenie sekundy
	lcall lcd_dec_2
	
	ret

;---------------------------------------------------------------------
; Obsluga alarmu
;---------------------------------------------------------------------
clock_alarm:
	; sprawdzam czy minelo juz N sekund od ostatniego alarmu, jezeli tak, to gasze diode
	jb ALARM, keep_diode_unchanged
	mov A, SEC_SINCE_LAST_ALARM
	inc A
	mov SEC_SINCE_LAST_ALARM, A
	xrl A, ALARM_DURATION
	jnz keep_diode_unchanged
	
	setb ALARM
	mov SEC_SINCE_LAST_ALARM, #0

	; sprawdzam, czy kolejne elementy czasu sa zgodne z alarmem, jezeli nie to konczymy obsluge alarmu
keep_diode_unchanged:
	mov A, ALARM_HOUR
	xrl A, HOUR
	jnz end_alarm
	
	mov A, ALARM_MIN
	xrl A, MIN
	jnz end_alarm
	
	mov A, ALARM_SEC
	xrl A, SEC
	jnz end_alarm
	
	; godzina zgodna z alarmem - uruchamiana jest dioda
	clr ALARM
	mov SEC_SINCE_LAST_ALARM, #0
	
end_alarm:
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
	setb ACC.7					; dopelniam brakujacy bit komendy
	lcall lcd_write_cmd

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
; Zapis komendy do LCD
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
; Inicjowanie wyswietlacza
;---------------------------------------------------------------------
lcd_init:
	
	mov A, #00111000b			; ustalenie trybu pracy
	lcall lcd_write_cmd
	
	mov A, #00000110b			; ustalenie trybu wprowadzania
	lcall lcd_write_cmd
	
	mov A, #00001111b			; kontrola widocznosci elementu lcd
	lcall lcd_write_cmd
	
	mov A, #00000001b			; wyczyszczenie ekranu
	lcall lcd_write_cmd

	ret

END