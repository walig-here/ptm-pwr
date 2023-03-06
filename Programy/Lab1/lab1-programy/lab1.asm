;=====================================================================
; 						DEKLARACJA SEGMENTÓW

TEST_CODE	SEGMENT CODE					; kod testów procedur	
TASK_CODE	SEGMENT CODE					; kod realizujacy polecenia z listy zadan

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
			MOV			R0, #30h			; liczba w komorkach IRAM 30h i 31h
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
; ZADANIE 1 - Procedura
; Inkrementuje liczbe dwubajtowa zapisana w pamieci IRAM.
; Wejscie:	R0 - adres mlodszego bajtu liczby
; Wyjscie: 	
; Uzywane: 
;---------------------------------------------------------------------
task1:		
	
			MOV			A, R0				; Zapisanie adresu kórki zawierajacej starszy bit w rejestrze R1
			INC			A
			MOV			R1, A
			CLR			A
			
			MOV			@R0, #LOW(256)		; Wprowadzenie wartosci 2-bajtowej do pamieci
			MOV			@R1, #HIGH(256)
			
			RET
		
		
;=====================================================================	
;						DEKLARACJA ZMIENNYCH

;---------------------------------------------------------------------
; Zadanie 1 - Zmienne
;---------------------------------------------------------------------

;=====================================================================	
;						STALE

;---------------------------------------------------------------------
; Zadanie 1 - Stale
;---------------------------------------------------------------------
	

;=====================================================================	

END