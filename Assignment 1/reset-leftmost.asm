; reset-leftmost.asm
; CSC 230: Fall 2024
;
; Code provided for Assignment #1
;
; Mike Zastre (2024-Sept-19)

; This skeleton of an assembly-language program is provided to help you
; begin with the programming task for A#1, part (b). In this and other
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
; Your task: You are to take the bit sequence stored in R16,
; and to reset the leftmost contiguous sequence of set bits
; by storing this new value in R25. For example, given
; the bit sequence 0b01100111, resetting the leftmost
; contigous sequence of set bits will produce 0b00000111.
; As another example, given the bit sequence 0b10110110,
; the result will be 0b00110110.
;
; Your solution must work, of course, for bit sequences other
; than those provided in the example. (How does your
; algorithm handle a value with no set bits? with all set bits?)

; ANY SIGNIFICANT IDEAS YOU FIND ON THE WEB THAT HAVE HELPED
; YOU DEVELOP YOUR SOLUTION MUST BE CITED AS A COMMENT (THAT
; IS, WHAT THE IDEA IS, PLUS THE URL).

    .cseg
    .org 0

; ==== END OF "DO NOT TOUCH" SECTION ==========

	;ldi R16, 0b01100111
	;ldi R16, 0b10110110
	;ldi r16, 0b11111111
	;ldi r16, 0b00000000
	ldi r16, 0b001110010

	; THE RESULT **MUST** END UP IN R25

; **** BEGINNING OF "STUDENT CODE" SECTION **** 

; Your solution here.

; Step 1: Initialize registers
    mov r25, r16 ; Copy r16 to r25 for result manipulation
    ldi r18, 0b10000000 ; Initialize mask in r18 (starting with MSB)
    clr r19 
    
find_set_bit:
    ; Step 2: Shift the mask left until a set bit in r16 is found, we will use r20 as a temporary storage register for the mask to make changes easier.
    tst r25 ; Test if r16 has any set bits at all
    breq no_set_bits 
    mov r20, r18 
    and r20, r16 ; Apply mask to r16 (check MSB)
    breq next_bit 
    
    ; Step 3: Once the first set bit is found, identify contiguous bits
    or r19, r18 ; Add current bit to r19 to track contiguous set bits

check_next_bit:
    lsr r18 
    mov r20, r18 
    and r20, r16 
    breq reset_bits 
    or r19, r18 ; If next bit is set, add to contiguous bits
    rjmp check_next_bit

next_bit:
    lsr r18 
    rjmp find_set_bit

reset_bits:
    ; Step 4: Reset the leftmost contiguous bits using r19 as a mask
    com r19 ; Complement r19 to turn 1s into 0s
    and r25, r19 ; Apply the mask to clear contiguous set bits
    rjmp done 

no_set_bits:
    clr r25 

done:


; **** END OF "STUDENT CODE" SECTION ********** 



; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
reset_leftmost_stop:
    rjmp reset_leftmost_stop

; ==== END OF "DO NOT TOUCH" SECTION ==========
