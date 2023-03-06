
		;--------------------------------------------
		; Program dzieli dwie zadane liczby przez siebie.
		; Zapisuje wynik i reszte z dzielenie do pamieci IRAM.
		;--------------------------------------------
		; Deklaracja segmentów
		main  	SEGMENT  CODE
		storage SEGMENT  DATA
			
		;--------------------------------------------
		; Stale
		dividend SET 36
		divisor SET 5	
		
		;--------------------------------------------		
		; Rezerwacja miejsca w pamieci		
		RSEG  storage
		result:	DS  1
		reminder: DS 1
		
		;--------------------------------------------
		; Program
		CSEG AT 0
			
			LJMP  jump
			
		RSEG  main
			
jump:		
			MOV  A,#dividend
			MOV  B,#divisor
			
			DIV  AB
			
			MOV  result, A
			CLR  A
			MOV  reminder, B
			MOV  B,#0
			
		END		
		;--------------------------------------------