;---------------------------------------------------------------------------
;		# SEGMENTY #

PROCEDURES	SEGMENT CODE

;---------------------------------------------------------------------------
;		# BLOK STALYCH #

LEDS	EQU	P1								; diody LED na P1 (0=ON)
	
TIME_MS	EQU	50								; czas w [ms]
CYCLES	EQU	(1000 * TIME_MS)				; czas w cyklach (f = 12 MHz)
LOAD	EQU	(65536 - CYCLES - 15)			; wartosc ladowana do TH0|TL0

RIGHT	EQU	0								; kierunek przesuwania LED

;---------------------------------------------------------------------------
;		# BLOK ZMIENNYCH #

DSEG AT 30h
counter_50:	DS 1							; licznik w ramach sekundy
second: DS 1								; sekundy
minute: DS 1								; minuty
hour: DS 1 									; godziny

;---------------------------------------------------------------------------
;		# BLOK STARTOWY #

		CSEG AT 0
		SJMP loop
		
loop:
		LCALL delay_50ms					
		SJMP loop
		
		MOV R7, #0FFh
		LCALL delay_nx50ms					
		SJMP loop
		
		LCALL delay_timer_50ms
		SJMP loop
	
		LCALL init_time
continue_update_time:
		LCALL delay_timer_50ms	
		LCALL update_time
		SJMP continue_update_time
		
		
loop_led_1:
		MOV R7, #10
		LCALL delay_nx50ms
		LCALL leds_change_1
		SJMP loop_led_1
			
loop_led_2:
		MOV R7, #10
		LCALL delay_nx50ms
		LCALL leds_change_2
		SJMP loop_led_2

;---------------------------------------------------------------------------
;		# BLOK PROCEUDUR #

		RSEG PROCEDURES

;---------------------------------------------------------------------------
; Opoznienie 50 ms (zegar 12 MHz)
;---------------------------------------------------------------------------
delay_50ms:									; 2 cykle
		MOV R0, #97							; 1 cykl
			
outer_loop:
		MOV R1, #255						; 1 cykl * 97
inner_loop:
		DJNZ R1, inner_loop					; 2 cykle * 255 * 97
		DJNZ R0, outer_loop					; 2 cykle * 97
	
		MOV R0, #116						; 1 cykl
complementary_loop:
		DJNZ R0, complementary_loop			; 2 cykle * 119
	
		NOP
		RET									; 2 cykle
		
		
;---------------------------------------------------------------------
; Opoznienie n * 50 ms (zegar 12 MHz)
; R7 - czas x 50 ms
;---------------------------------------------------------------------
delay_nx50ms:		
		DEC R7								; 1 cykl | zmniejszam o 1, gdyz w wypadku wykonania pelnych n odliczen zawsze bedziemy mieli blad 6us, to za duzo!
		MOV A, R7							; 1 cykl
		JZ start_counting_last_50ms			; 2 cykle, jezeli mamy wykonac zero 0 plenych wywolan delay_50ms, to od razu przechodze do odliczania dopelniajacego

next_50ms:
		LCALL delay_50ms					; 50k cykli * R7
		DJNZ R7, next_50ms					; 2 cykle * R7

start_counting_last_50ms:
		MOV R0, #97							; 1 cykl | trzeba dopelnic odliczanie ostatnich 50ms
outer_loop_last_50ms:
		MOV R1, #255						; 1 cykl * 97
inner_loop_last_50ms:
		DJNZ R1, inner_loop_last_50ms		; 2 cykle * 255 * 97
		DJNZ R0, outer_loop_last_50ms		; 2 cykle * 97
		
		MOV R0, #115						; 1 cykl
final_loop_nx50ms:
		DJNZ R0, final_loop_nx50ms			; 2 cykle * 115
		
		NOP									; 1 cykl
		RET
		
		
;---------------------------------------------------------------------
; Opoznienie 50 ms z uzyciem Timera 0 (zegar 12 MHz)
;---------------------------------------------------------------------
delay_timer_50ms:							; 2 cykle
		
		CLR TR0								; zatrzymuje licznik | 1 cykl
		
		MOV A, #00001001b					; wlaczam licznik 0 w trybie 16-bitowym | 1 cykl
		ORL TMOD, A							; 1 cykl
		
		MOV TL0, #LOW(LOAD)					; wczytuje wartosci do rejestrow licznika | 2 cykle
		MOV TH0, #HIGH(LOAD)				; 2 cykle
		
		CLR TF0								; wyczyszczenie flagi przepelnienia licznika | 1 cykl
		
		SETB TR0							; wlaczenie timera | 1 cykl
		
wait_for_overflow:
		JNB TF0, wait_for_overflow			; czekam na odliczenie czasu przez timer

		RET									; 2 cykle
		
		
;---------------------------------------------------------------------
; Inicjowanie czasu w zmiennych: HOUR, MIN, SEC, SEC_100
;---------------------------------------------------------------------
init_time:
		
		MOV	counter_50, #20
		MOV second, #59
		MOV minute, #59
		MOV hour, #23
		
		RET
		

;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | CNT_50
; Przy wywolywaniu procedury co 50 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;
; Wyjscie: CY - sygnalizacja zmiany sekund (0 - nie, 1 - tak)
;---------------------------------------------------------------------
update_time:
	CLR F0
	
	DEC counter_50							; aktualizacja licznika 50ms, jezeli nie osiagnelismy 0, to nie aktualizujemy dalej czasu
	MOV A, counter_50
	JNZ stop_time_update
	MOV	counter_50, #20
	SETB F0
	
	INC	second								; aktualizacja licznika sekund, jezeli nie osiagnelismy 60 sekund, to nie aktualizujemy dalej czasu
	MOV A, second
	XRL A, #60
	JNZ stop_time_update
	MOV second, A
	
	INC	minute								; aktualizacja licznika minut, jezeli nie osiagnelismy 60 minut, to nie aktualizujemy dalej czasu
	MOV A, minute
	XRL A, #60
	JNZ stop_time_update
	MOV minute, A
	
	INC	hour								; aktualizacja licznika godzin, jezeli nie osiagnelismy 24 godzin, to nie aktualizujemy dalej czasu
	MOV A, hour
	XRL A, #24
	JNZ stop_time_update
	MOV hour, A
	
	
stop_time_update:	
	MOV C, F0
	RET
	
;---------------------------------------------------------------------
; Zmiana stanu LEDS - dioda wedrujaca w obu kierunkach
;---------------------------------------------------------------------
leds_change_1:
	MOV A, LEDS
	
	JB RIGHT, rotate_right					; Jezeli dioda przemieszcza sie w lewo, to przesuwamy w lewo i sprawdzamy, czy nie przesunelismy sie juz maksymalnie
	RLC A
	JB ACC.7, rotated						; Jezeli jestesmy juz maksymalnie na lewo, to zaczynamy przemieszczanie w prawo
	SETB RIGHT
	JMP rotated

rotate_right:								; W przeciwnym wypadku przesuwamy w prawo i sprawdzamy, czy nie przesunelismy sie juz maksymalnie
	RRC A
	JB ACC.0, rotated						; Jezeli jestesmy juz maksykalnie na prawo, to zaczynamy przemieszczanie w lewo
	CLR RIGHT

rotated:
	MOV LEDS, A								; zapalamy odpowiednia diode
	RET

;---------------------------------------------------------------------
; Zmiana stanu LEDS - narastajacy pasek od lewej
;---------------------------------------------------------------------
leds_change_2:
	
	MOV A, LEDS								; Jezeli wszystjkie sie pala, to gasze wszystkie diody
	JB	ACC.7, light_up_next
	MOV A, #0FFh
	SJMP update_diodes
	
light_up_next:
	CLR C									; Zapalam kolejne diody patrzac od prawej
	RLC A
	
update_diodes:
	MOV LEDS, A
	RET
		
;---------------------------------------------------------------------------
	END