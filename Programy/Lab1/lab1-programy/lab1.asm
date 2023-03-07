;=====================================================================
; 						DEKLARACJA SEGMENTÓW

TEST_CODE	SEGMENT CODE						; kod testów procedur	
TASK_CODE	SEGMENT CODE						; kod realizujacy polecenia z listy zadan
UTIL_CODE	SEGMENT CODE						; kod realizujace funkcje pomocnicze	
	
FLAGS		SEGMENT BIT							; flagi bitowe

;=====================================================================	
;						STALE I ZMIENNE

NUM_CONST_1	EQU			256						; Liczba 1
NUM_CONST_2 EQU			456						; Liczba 2
	
VALUE		EQU			10						; Wartosc do zadania 8
LENGTH		EQU			45						; Dlugosc buforu do zadania 8	
	
ADR_IRAM	EQU			30h						; Adresy bloków liczb 2-bajtowych w IRAM
ADR_XRAM	EQU			8000h					; Adresy bloków liczb 2-bajtowych w XRAM
	
MASK		EQU			0000111111110000b		; Maska 2-bajtowa	
	
			DSEG AT		ADR_IRAM 
num_iram_1:	DS			2						; Liczba 2-bajtowa, zapisana w IRAM	
num_iram_2:	DS			2						; Liczba 2-bajtowa, zapisana w IRAM
	
			XSEG AT		ADR_XRAM 
num_xram_1:	DS			2						; Liczba 2-bajtowa, zapisana w XRAM	
	
			RSEG		FLAGS
overflow:	DBIT		1						; Wskazuje czy wynik operacji jest przepelniony					
negative:	DBIT		1						; Wskazuje czy wynik operacji jest negatywny

;=====================================================================
;						KOD STARTOWY

			CSEG AT		0
			
			MOV			R0, #num_iram_1			; Wczytanie liczby 1 do IRAM
			MOV			R2, #LOW(NUM_CONST_1)
			MOV			R3, #HIGH(NUM_CONST_1)
			LCALL		define_iram_number
			
			MOV			R0, #num_iram_2			; Wczytanie liczby 2 do IRAM
			MOV			R2, #LOW(NUM_CONST_2)
			MOV			R3, #HIGH(NUM_CONST_2)
			LCALL		define_iram_number
			
			MOV			DPTR, #num_xram_1		; Wczytanie liczby 1 do XRAM
			MOV			R2, #LOW(NUM_CONST_1)
			MOV			R3, #HIGH(NUM_CONST_1)
			LCALL		define_xram_number

			LJMP		loop					; test wielokrotny

;=====================================================================
; 						TESTY POPRAWNOSCI
		
			RSEG		TEST_CODE
				
;---------------------------------------------------------------------
; Test procedury - wywolanie powtarzane
;---------------------------------------------------------------------
		
			MOV			R0, #num_iram_1			; Zadanie 1
			LCALL		task1
			SJMP		loop
			
			MOV			DPTR, #num_xram_1		; Zadanie 2
			LCALL		task2
			SJMP		loop					
			
			MOV			R0, #num_iram_1			; Zadanie 3
			MOV			R1, #num_iram_2
			LCALL		task3
			SJMP		loop					
			
			MOV			R6, num_iram_1			; Zadanie 4
			MOV			R7, (num_iram_1+1)
			LCALL		task4
			MOV			num_iram_1, R6
			MOV			(num_iram_1+1), R7
			SJMP		loop	
				
			MOV			R6, num_iram_1			; Zadanie 5
			MOV			R7, (num_iram_1+1)
			LCALL		task5
			MOV			num_iram_1, R6
			MOV			(num_iram_1+1), R7
			SJMP		loop	
		
			MOV			R6, num_iram_1			; Zadanie 6
			MOV			R7, (num_iram_1+1)
			LCALL		task6
			SJMP		loop	
loop:				
			MOV			DPTR, #(num_xram_1+2)	; Zadanie 8
			MOV			R2, #LENGTH
			LCALL		task8
			SJMP		loop	

;=====================================================================		
;						REALIZACJA ZADAN
	
			RSEG 		TASK_CODE

;---------------------------------------------------------------------
; ZADANIE 1
; Inkrementuje liczbe dwubajtowa zapisana w pamieci IRAM.
; Wejscie:	R0 - adres mlodszego bajtu liczby
; Wyjscie: 	Zinkrementowana liczba zapisana na 2 bajtach pamieci IRAM.
; Uzywane:	R0
;---------------------------------------------------------------------
task1:	
			INC			@R0							; Inkrementacja mlodszego
			CJNE		@R0, #0, end_taks1
			INC			R0
			
			CJNE		@R0, #0FFh, not_overflow	; Sprawdzenie warunku aktywacji flagi
			SETB		overflow
not_overflow:
			INC			@R0							; Inkrementacja starszego
end_taks1:  
			MOV			R0, #0						; Koniec procdury
			RET								


;---------------------------------------------------------------------
; ZADANIE 2
; Dekrementuje liczbe dwubajtowa zapisana w pamieci XRAM.
; Wejscie:	DPTR - adres mlodszego bajtu liczby
; Wyjscie: 	Zdekrementowania liczba zapisana na 2 bajtach pamieci IRAM
;			od komórki o adresie NUM2_ADR.
; Uzywane:	DPTR, A
;---------------------------------------------------------------------
task2:
			MOVX		A, @DPTR					; Dekrementacja mlodszego
			DEC			A
			MOVX		@DPTR, A
			CJNE		A, #0FFh, end_task2
			INC			DPTR
			MOVX		A, @DPTR
			
			CJNE		A, #0, not_negative			; Sprawdzenie warunku aktywacji flagi
			SETB		negative
not_negative:	
			DEC			A							; Dekrementacja starszego
			MOVX		@DPTR, A
end_task2:			
			RET
			

;---------------------------------------------------------------------
; ZADANIE 3
; Dodanie liczb dwubajtowych w pamieci wewnetrznej (IRAM)
; Wejscie:	R0 - adres mlodszego bajtu (Lo) skladnika A oraz sumy (A <- A + B)
;			R1 - adres mlodszego bajtu (Lo) skladnika B
; Wyjscie: 	Suma liczb A i B zapisana w miejscu skladnika A
; Uzywane:	R0, R1, A
;---------------------------------------------------------------------
task3:
			MOV			A, @R0						; Dodawanie mlodszych bitow
			ADD			A, @R1
			MOV			@R0, A
			
			INC			R0							; Dodawanie starszych bitow
			INC			R1
			MOV			A, @R0
			ADDC		A, @R1
			MOV			@R0, A
			
			JNC			end_task3					; Ustalenie flagi przepelnienia
			SETB		overflow
end_task3:
			RET										; Powrot
			

;---------------------------------------------------------------------
; ZADANIE 4
; Wyzerowanie bitow 15 - 12 i 3 - 0 w liczbie dwubajtowej
; Wejscie:	R7|R6 - liczba dwubajtowa
; Wyjscie: 	R7|R6 - liczba po modyfikacji
; Uzywane:	R7, R6, A
;---------------------------------------------------------------------
task4:
			MOV 		A, R6						; Modyfikacja mlodszego bajtu
			ANL			A, #NOT(LOW(MASK))
			MOV			R6, A
			
			MOV			A, R7						; Modufikacja starszego bajtu
			ANL			A, #NOT(HIGH(MASK))
			MOV			R7, A
			
			RET										; Powrot
			
;---------------------------------------------------------------------
; ZADANIE 5
; Rotacja w prawo liczby dwubajtowej (cykliczna) 
; Wejscie:	R7|R6 - liczba dwubajtowa
; Wyjscie: 	R7|R6 - liczba po modyfikacji
; Uzywane:	R7, R6, A, CY
;---------------------------------------------------------------------			
task5:
			MOV			A, R6						; Przesuniecie mlodszego bajtu
			CLR			C
			RRC			A
			MOV			R6, A
			
			MOV			A,R7						; Przesuniecie starszego bajtu i dodanie do niego bitu 0 przeusnietego z mlodszego bajtu(i ile byl rowny 1)
			JC			add_0_bit
			CLR			C
			RRC			A
			SJMP		next_condition
add_0_bit:		
			CLR			C
			RRC			A
			SETB		ACC.7 
next_condition:
			MOV			R7, A						; Sprawdzenie czy trzeba przesunac bit 0 ze starszego bajtu na bit 7 mlodszego bajtu
			JNC			end_task5
			MOV			A, R6
			SETB		ACC.7
			MOV			R6, A
end_task5:
			RET
			
;---------------------------------------------------------------------
; ZADANIE 6
; Okreslenie bitu parzystosci dla liczby dwubajtowej
; Wejscie:	R7|R6 - liczba dwubajtowa
; Wyjscie: 	CY - bit parzystosci
; Uzywane:	R7, R6, CY
;---------------------------------------------------------------------				
task6:
		CLR				C							; Czyscimy flage CY
		
		MOV				A, R6						; Sprawdzamy parzystystosc mlodszego bajtu i ja zapamietujemy
		JB				P, first_odd
		
		MOV				A, R7						; Sprawdzamy parzystosc starszego bajtu dla parzystego mlodszego
		JNB				P, whole_even
		SJMP			whole_odd
first_odd:	
		MOV				A, R7						; Sprawdzamy parzystosc starszego bajtu dla nieparzystego mlodszego
		JNB				P, whole_odd
whole_even:
		RET	
whole_odd:	
		SETB			C	
		RET
		
;---------------------------------------------------------------------
; ZADANIE 8
; Wypelnianie obszaru pamieci zewnetrznej (XRAM) wartoscia 10
; Wejscie:	DPTR - adres poczatku obszaru
;			R2 - dlugosc obszaru
; Uzywane:	DPTR, R2, A
;---------------------------------------------------------------------			
task8:
			MOV			A, #VALUE
			CJNE		R2, #0, begin_loop			; Sprawdzamy czy nie podano blednej dlugosci bufora
			SJMP		end_task8
begin_loop:	
			MOVX		@DPTR, A					; Wypelniamy bufor w XRAM
			INC			DPTR
			DJNZ		R2, begin_loop
end_task8:
			RET

;=====================================================================	
;						PROCEDURY POMOCNICZE

			RSEG 		UTIL_CODE

;---------------------------------------------------------------------
; Wczytuje do pamieci IRAM liczbe 2-bajtowa.
; Wejscie:	R0 - adres pierwszego bajtu liczby
;			R2 - mlodszy bajt liczby
;			R3 - starszy bajt liczby
; Wyjscie:  Liczba zapisana na 2 bajtach pamieci IRAM, gdzie mlodszy
;			bajt znajduje sie pod @R0 a starszy w kolejnej komórce
; Uzywane:	R0, R2, R3, A
;---------------------------------------------------------------------
define_iram_number:
			MOV			A, R2						; Wczytanie liczby
			MOV			@R0, A
			INC			R0
			MOV			A, R3
			MOV			@R0, A							
			
			RET										; Powrót
		
		
;---------------------------------------------------------------------
; Wczytuje do pamieci XRAM liczbe 2-bajtowa.
; Wejscie:	DPTR - adres mlodszego bajtu liczby
;			R2 - mlodszy bajt liczby
;			R3 - starszy bajt liczby
; Wyjscie:  Liczba zapisana na 2 bajtach pamieci XRAM, gdzie mlodszy
;			bajt znajduje sie pod @DPTR a starszy w kolejnej komórce
; Uzywane:	DPTR, R2, R3, A
;---------------------------------------------------------------------
define_xram_number:
			MOV			A, R2
			MOVX		@DPTR, A
			MOV			A, R3
			INC			DPTR
			MOVX		@DPTR, A
			
			RET 									; Powrot

;=====================================================================

END