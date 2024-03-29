;------------------------------------------------------------------
;						BLOK SEGMENT�W

PROCEDURES	SEGMENT	CODE
UTIL_PROC	SEGMENT CODE
STACK		SEGMENT	DATA

;------------------------------------------------------------------
;						BLOK STALYCH

BLOCK_LEN	EQU	5								; dlugosc bufora w pamieci XRAM/IRAM
XBLOCK_ADR	EQU	0h								; adres poczatku bufora w pamieci XRAM
IBLOCK_ADR	EQU	30h								; adres poczatku bufora w pamieci IRAM

;------------------------------------------------------------------
; 						BLOK STARTOWY
			
			CSEG AT	0			
			SJMP loop	

			MOV	DPTR, #XBLOCK_ADR				; Zadanie 1
			MOV	R2, #BLOCK_LEN
			LCALL sum_xram
			SJMP loop
	
			MOV	DPTR, #XBLOCK_ADR				; Zadanie 2
			MOV	R2, #BLOCK_LEN
			MOV	R0, #IBLOCK_ADR
			LCALL copy_xram_iram_inv
			SJMP loop
				
			MOV	DPTR, #XBLOCK_ADR				; Zadanie 3
			MOV	R2, #BLOCK_LEN
			MOV	R0, #IBLOCK_ADR
			LCALL copy_iram_xram_z
			SJMP loop	
loop:	
			MOV	DPTR, #XBLOCK_ADR				; Zadanie 4
			MOV	R2, #BLOCK_LEN
			MOV	R0, #LOW(000Ah)
			MOV	R1, #HIGH(000Ah)
			LCALL copy_xram_xram_2
			SJMP loop
			
			MOV	R2, #BLOCK_LEN					; Zadanie 5
			MOV	R0, #IBLOCK_ADR
			LCALL count_range
			SJMP loop

;------------------------------------------------------------------
; 						BLOK PROCEDUR
			
			RSEG PROCEDURES

;---------------------------------------------------------------------
; Sumowanie bloku danych w pamieci zewnetrznej (XRAM)
;
; Wejscie: DPTR  - adres poczatkowy bloku danych
;          R2    - dlugosc bloku danych
; Wyjscie: R7|R6 - 16-bit suma elementow bloku (Hi|Lo)
;---------------------------------------------------------------------
sum_xram:
			MOV	A, R2							; sprawdzenie czy wskazany blok nie jest zerowej dlugosci
			JZ	reached_sum_buffers_end
			
			MOV	R6, #0							; czyszczenie rejestr�w wynikowych
			MOV	R7, #0
			
add_next:	CLR	C								; dodanie do mlodszego bajtu zawartosci z bloku danych
			MOVX A, @DPTR
			ADD	A, R6				
			MOV	R6, A
			
			MOV	A, R7							; dodanie ewentualnego przeniesienia do starszego bajtu
			ADDC A, #0
			MOV	R7, A
			
			INC	DPTR							; przejscie do kolejnej kom�rki pamieci (o ile nie dotarlismy do konca bufora)
			DJNZ R2, add_next
			
reached_sum_buffers_end:
			RET									; dotarto do konca bufora
			
		
;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci zewnetrznej (XRAM) do wewnetrznej (IRAM)
; Przy kopiowaniu powinna byc odwrocona kolejnosc elementow
;
; Wejscie: DPTR - adres poczatkowy obszaru zrodlowego
;          R0   - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_iram_inv:		
			MOV	A, R2							; sprzawdzenie, czy wskazany blok nie jest zerowej dlugosci
			JZ reached_cpy_xram_buffers_end
			
			ADD	A, R0							; przesuniecie wskaznika IRAM na koniec obszaru docelowego
			DEC	A
			MOV	R0, A
			
copy_next_xram:
			MOVX A, @DPTR						; kopiowanie danych z XRAM do IRAM
			MOV	@R0, A
			
			DEC	R0								; przesuniecie wskaznikow 
			INC	DPTR
			DJNZ R2, copy_next_xram

reached_cpy_xram_buffers_end:
			RET


;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci wewnetrznej (IRAM) do zewnetrznej (XRAM)
; Przy kopiowaniu powinny byc pominiete elementy zerowe
;
; Wejscie: R0   - adres poczatkowy obszaru zrodlowego
;          DPTR - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_iram_xram_z:
			MOV	A, R2							; sprzawdzenie, czy wskazany blok nie jest zerowej dlugosci
			JZ reached_cpy_iram_buffers_end

copy_next_iram:
			MOV	A, @R0							; sprawdzenie, czy wartosc komorki jest niezerowa
			JZ iram_value_is_zero
			
												; wykonanie kopii do XRAM i przesuniecie wskaznika w XRAM
			MOVX @DPTR, A
			INC DPTR
			
iram_value_is_zero:
			INC R0								; przesuniecie wskaznika w IRAM, przejscie do kopiowania kolejnej komorki
			DJNZ R2, copy_next_iram

reached_cpy_iram_buffers_end:
			RET
			
;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci zewnetrznej (XRAM -> XRAM)
; Przy kopiowaniu elementy niezerowe powinny byc podwojone
;
; Wejscie: DPTR  - adres poczatkowy obszaru zrodlowego
;          R1|R0 - adres poczatkowy obszaru docelowego
;          R2    - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_xram_2:
			MOV	A, R2							; sprawdzenie, czy wskazany blok nie jest zerowej dlugosci
			JZ reached_xram_end_2
			
			MOV P2, R1
copy_next_xram_to_xram:
			MOVX A, @DPTR						; kopiuje dane do miejca docelowego
			MOVX @R0, A
			
			LCALL increment_r1r0_pointer		; zwiekszam adres miejsca docelowego, zachowujac jednoczesnie adres miejsca zrodlowego
			
			JZ check_cpy_next					; jezeli element jest niezerowy do kopiuje go drugi raz
			MOVX @R0, A
			LCALL increment_r1r0_pointer
			
check_cpy_next:
			INC DPTR
			DJNZ R2, copy_next_xram_to_xram
reached_xram_end_2:
			RET

;---------------------------------------------------------------------
; Zliczanie w bloku danych w pamieci wewnetrznej (IRAM)
; liczb mieszczacych sie w przedziale domknietym <10,100>
;
; Wejscie: R0 - adres poczatkowy bloku danych
;          R2 - dlugosc bloku danych
; Wyjscie: A  - liczba elementow spelniajacych warunek
;---------------------------------------------------------------------
count_range:
			MOV	A, R2							; sprawdzenie, czy wskazany blok nie jest zerowej dlugosci
			JZ reached_count_end
			CLR	A								; wyzerowanie licznika
			
analyze_next:
			
			CJNE @R0, #10, compared_to_10		; sprawdzenie, czy @R0<10
compared_to_10:
			JC check_loop_condition			
										
			CJNE @R0, #101, compared_to_100 	; sprawdzenie, czy @R0>100
compared_to_100:
			JNC check_loop_condition
			
			INC	A								; zliczenie kom�rki
check_loop_condition:
			INC	R0
			DJNZ R2, analyze_next
			
reached_count_end:
			RET

;------------------------------------------------------------------
; 						BLOK PROCEDUR POMOCNICZYCH
			
			RSEG			UTIL_PROC

;------------------------------------------------------------------
; Inkrementuje 16-bitowy wskaznik R1|R0
;------------------------------------------------------------------
increment_r1r0_pointer:
			INC R0
			CJNE R0, #0, end_increment
			INC P2

end_increment:
			RET
		
;------------------------------------------------------------------
			END