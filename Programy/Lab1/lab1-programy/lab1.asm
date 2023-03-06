;=====================================================================
; 						DEKLARACJA SEGMENTÓW

TEST_CODE	SEGMENT CODE					; kod testów procedur	
TASK_CODE	SEGMENT CODE					; kod realizujacy polecenia z listy zadan

;=====================================================================	
;						STALE

;---------------------------------------------------------------------
; Zadanie 1 - Stale
;---------------------------------------------------------------------
NUM 		EQU			16				; Liczba 2-batjowa
NUM_ADR		EQU			30h				; Adres mlodszego bitu liczby NUM

;=====================================================================
;						KOD STARTOWY

			CSEG AT		0
			LJMP		test_once		; test_once lub test_multi

;=====================================================================
; 						TESTY POPRAWNOSCI
		
			RSEG		TEST_CODE
		
;---------------------------------------------------------------------
; Test procedury - wywolanie jednorazowe
;---------------------------------------------------------------------
test_once:
			MOV			R0, #NUM_ADR		; liczba w komorkach IRAM 30h i 31h
			LCALL		task1				; wywolanie procedury
			SJMP		$					; petla bez konca


;---------------------------------------------------------------------
; Test procedury - wywolanie powtarzane
;---------------------------------------------------------------------
test_multi:
loop:		MOV			DPTR, #8000h		; liczba w komorkach XRAM 8000h i 8001h
			LCALL		task1				; wywolanie procedury
			SJMP		loop				; powtarzanie

;=====================================================================		
;						REALIZACJA ZADAN
	
			RSEG 		TASK_CODE

;---------------------------------------------------------------------
; ZADANIE 1
; Inkrementuje liczbe dwubajtowa zapisana w pamieci IRAM.
; Wejscie:	R0 - adres mlodszego bajtu liczby
; Wyjscie: 	Zinkrementowana liczba zapisana na 2 bajtach pamieci IRAM
;			od komórki o adresie NUM_ADR
; Uzywane:	R0
;---------------------------------------------------------------------
task1:	
			MOV			@R0, #LOW(NUM)		; Wprowadzenie wartosci 2-bajtowej do pamieci
			INC			R0
			MOV			@R0, #HIGH(NUM)
			DEC			R0
			
			INC			@R0					; Wlasciwa inkrementacja - wykorzystanie CJNE
			CJNE		@R0, #0, end_taks1
			INC			R0
			INC			@R0
end_taks1:  
			MOV			R0, #0				; Koniec procdury
			RET								
		
		
;=====================================================================	
;						DEKLARACJA ZMIENNYCH

;---------------------------------------------------------------------
; Zadanie 1 - Zmienne
;---------------------------------------------------------------------	

;=====================================================================	

END