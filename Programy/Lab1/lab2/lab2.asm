;------------------------------------------------------------------
;						BLOK SEGMENTÓW

PROCEDURES	SEGMENT	CODE

;------------------------------------------------------------------
;						BLOK STALYCH

BLOCK_LEN	EQU				2						; dlugosc bufora w pamieci XRAM/IRAM
XBLOCK_ADR	EQU				0h						; adres poczatku bufora w pamieci XRAM
IBLOCK_ADR	EQU				30h						; adres poczatku bufora w pamieci IRAM

;------------------------------------------------------------------
; 						BLOK STARTOWY
			
			CSEG AT			0
			SJMP			loop	
	
			MOV				DPTR, #XBLOCK_ADR
			MOV				R2, #BLOCK_LEN
			LCALL			sum_xram
			SJMP			loop
	
			MOV				DPTR, #XBLOCK_ADR
			MOV				R2, #BLOCK_LEN
			MOV				R0, #IBLOCK_ADR
			LCALL			copy_xram_iram_inv
			SJMP			loop
loop:			
			MOV				DPTR, #XBLOCK_ADR
			MOV				R2, #BLOCK_LEN
			MOV				R0, #IBLOCK_ADR
			LCALL			copy_iram_xram_z
			SJMP			loop				

;------------------------------------------------------------------
; 						BLOK PROCEDUR
			
			RSEG			PROCEDURES

;---------------------------------------------------------------------
; Sumowanie bloku danych w pamieci zewnetrznej (XRAM)
;
; Wejscie: DPTR  - adres poczatkowy bloku danych
;          R2    - dlugosc bloku danych
; Wyjscie: R7|R6 - 16-bit suma elementow bloku (Hi|Lo)
;---------------------------------------------------------------------
sum_xram:
			MOV				R6, #0					; czyszczenie rejestrów wynikowych
			MOV				R7, #0
			
			MOV				A, R2					; sprawdzenie czy wskazany blok nie jest zerowej dlugosci
			JZ				reached_sum_buffers_end
			
add_next:
			CLR				C						; dodanie do mlodszego bajtu zawartosci z bloku danych
			MOVX			A, @DPTR
			ADD				A, R6				
			MOV				R6, A
			
			MOV				A, R7					; dodanie ewentualnego przeniesienia do starszego bajtu
			ADDC			A, #0
			MOV				R7, A
			
			INC				DPTR					; przejscie do kolejnej komórki pamieci (o ile nie dotarlismy do konca bufora)
			DJNZ			R2, add_next
			
reached_sum_buffers_end:
			RET										; dotarto do konca bufora
		
		
;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci zewnetrznej (XRAM) do wewnetrznej (IRAM)
; Przy kopiowaniu powinna byc odwrocona kolejnosc elementow
;
; Wejscie: DPTR - adres poczatkowy obszaru zrodlowego
;          R0   - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_iram_inv:		
			MOV				A, R2					; sprzawdzenie, czy wskazany blok nie jest zerowej dlugosci
			JZ				reached_cpy_xram_buffers_end
			
			ADD				A, R0					; przesuniecie wskaznika IRAM na koniec obszaru docelowego
			DEC				A
			MOV				R0, A
			
copy_next_xram:
			MOVX			A, @DPTR				; kopiowanie danych z XRAM do IRAM
			MOV				@R0, A
			
			DEC				R0						; przesuniecie wskaznikow 
			INC				DPTR
			DJNZ			R2, copy_next_xram

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
			MOV				A, R2					; sprzawdzenie, czy wskazany blok nie jest zerowej dlugosci
			JZ				reached_cpy_iram_buffers_end

copy_next_iram:
			MOV				A, @R0					; sprawdzenie, czy wartosc komorki jest niezerowa
			JZ				iram_value_is_zero
			
			MOV				A, @R0					; wykonanie kopii do XRAM i przesuniecie wskaznika w XRAM
			MOVX			@DPTR, A
			INC				DPTR
			
iram_value_is_zero:
			INC				R0						; przesuniecie wskaznika w IRAM, przejscie do kopiowania kolejnej komorki
			DJNZ			R2, copy_next_iram

reached_cpy_iram_buffers_end:
			RET

;------------------------------------------------------------------
;						BLOK ZMIENNYCH

;------------------------------------------------------------------
			END