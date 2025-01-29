; bcd-subtraction.asm
; CSC 230: Fall 2024
;
; Code provided for Assignment #1
;
; Mike Zastre (2024-Sept-19)

; This skeleton of an assembly-language program is provided to help you
; begin with the programming task for A#1, part (c). In this and other
; files provided through the semester, you will see lines of code
; indicating "DO NOT TOUCH" sections. You are *not* to modify the
; lines within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; In a more positive vein, you are expected to place your code with the
; area marked "STUDENT CODE" sections.

; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; Your task: Two packed Binary Coded Decimal (BCD) numbers are
; are provided in R16 and R17. You are to subtract the BCD number
; in R16 from the BCD number in R17, such that the result in BCD is
; stored in R25.
;
; For example, we know that 51 - 39 equals 12. If
; the digits are encoded as BCD, we would have
;   *  0x39 in R16
;   *  0x51 in R17
; with the result of the subtraction being:
;   * 0x12 in R25
;
; Your solution, of course, must work for many
; more values that the ones shown above. However,
; to simplify your work, you may assume that the
; BCD in R16 will never be larger than the BCD
; stored in R17 (i.e. the BCD result in R25 will
; never represent a negative number).
;

; ANY SIGNIFICANT IDEAS YOU FIND ON THE WEB THAT HAVE HELPED
; YOU DEVELOP YOUR SOLUTION MUST BE CITED AS A COMMENT (THAT
; IS, WHAT THE IDEA IS, PLUS THE URL).



    .cseg
    .org 0

	; Some test cases below for you to try. And as usual
	; your solution is expected to work with values other
	; than those provided here.
	;
	; Your code will always be tested with legal BCD
	; values in r16 and r17 (i.e. no need for error checking).

	; 51 - 39 = 12
	;ldi r16, 0x39
	;ldi r17, 0x51
	ldi r16, 0x07
	ldi r17, 0x27

; ==== END OF "DO NOT TOUCH" SECTION ==========

; **** BEGINNING OF "STUDENT CODE" SECTION **** 

    ; Subtract lower nibble
	mov r18, r16        
	mov r19, r17        
	andi r18, 0x0F      ; Mask to get lower nibble
	andi r19, 0x0F      
	sub r19, r18        ; Subtract lower nibbles

	; Check borrow and apply BCD correction if necessary
    brcc no_adjust_lower
    ldi r20, 0x0A      ; Load 0x0A to adjust for BCD correction
    add r19, r20       ; Apply BCD correction
    sbc r20, r20       ; Set carry flag for upper nibble subtraction
no_adjust_lower:
	andi r25, 0xF0      
	or r25, r19         

	; Subtract upper nibble 
	mov r18, r16        
	mov r19, r17        
	swap r18            ; Swap nibbles to get upper nibbles
	swap r19            
	andi r18, 0x0F      ; Mask to get upper nibble
	andi r19, 0x0F      
	sbc r19, r18        ; Subtract upper nibbles with carry

	; Check borrow and apply BCD correction if necessary
    brcc no_adjust_upper
    ldi r20, 0x0A      
    add r19, r20
	    
no_adjust_upper:
	swap r19            
	andi r25, 0x0F      
	or r25, r19         

; **** END OF "STUDENT CODE" SECTION **********


; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
bcd_subtraction_end:
	rjmp bcd_subtraction_end

; ==== END OF "DO NOT TOUCH" SECTION ==========
