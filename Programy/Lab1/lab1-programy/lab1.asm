;=====================================================================
; 						DEKLARACJA SEGMENTÓW

TEST_CODE	SEGMENT CODE					; kod testów procedur	
TASK_CODE	SEGMENT CODE					; kod realizujacy polecenia z listy zadan

;=====================================================================	
;						STALE

;---------------------------------------------------------------------
; Zadanie 1 - Stale
;---------------------------------------------------------------------
NUM 		EQU			255				; Liczba 2-batjowa (0,511)
NUM_ADR		EQU			30h				; 

;=====================================================================
;						KOD STARTOWY

			CSEG AT		0
			LJMP		test_once

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
; Wyjscie: 	Zinkrementowana liczba zapisana na 2 bajtach pamieci ram
;			od komórki o adresie NUM_ADR
; Uzywane:	R0, R1, A
;---------------------------------------------------------------------
task1:		
			MOV			A, R0				; Zapisanie adresu starszego bajtu w rejestrze 1
			INC			A
			MOV			R1, A
			
			MOV			@R0, #LOW(NUM)		; Wprowadzenie wartosci 2-bajtowej do pamieci
			MOV			@R1, #HIGH(NUM)
			
			INC			@R0					; Wlasciwa inkrementacja - wykorzystanie CJNE
			CJNE		@R0, #0, end_taks1
			INC			@R1
end_taks1:  
			CLR			A					; Koniec procdury
			MOV			R0, #0
			MOV			R1, #0
			RET								
		
		
;=====================================================================	
;						DEKLARACJA ZMIENNYCH

;---------------------------------------------------------------------
; Zadanie 1 - Zmienne
;---------------------------------------------------------------------	

;=====================================================================	

END