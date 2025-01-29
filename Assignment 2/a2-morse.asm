; a2_morse.asm
; CSC 230: Fall 2024
;
; Student name: Lucas Hewgill
; Student ID: V01033481
; Date of completed work:
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2024-Oct-09)
; 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are 
; "DO NOT TOUCH" sections. You are *not* to modify the lines
; within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; I have added for this assignment an additional kind of section
; called "TOUCH CAREFULLY". The intention here is that one or two
; constants can be changed in such a section -- this will be needed
; as you try to test your code on different messages.
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

.include "m2560def.inc"

.cseg
.equ S_DDRB=0x24
.equ S_PORTB=0x25
.equ S_DDRL=0x10A
.equ S_PORTL=0x10B

	
.org 0
	; Copy test encoding (of SOS) into SRAM
	;
	ldi ZH, high(TESTBUFFER)
	ldi ZL, low(TESTBUFFER)
	ldi r16, 0x30
	st Z+, r16
	ldi r16, 0x37
	st Z+, r16
	ldi r16, 0x30
	st Z+, r16
	clr r16
	st Z, r16

	; initialize run-time stack
	ldi r17, high(0x21ff)
	ldi r16, low(0x21ff)
	out SPH, r17
	out SPL, r16

	; initialize LED ports to output
	ldi r17, 0xff
	sts S_DDRB, r17
	sts S_DDRL, r17

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION **** 
; ***************************************************

	; If you're not yet ready to execute the
	; encoding and flashing, then leave the
	; rjmp in below. Otherwise delete it or
	; comment it out.
	;rjmp stop

    ; The following seven lines are only for testing of your
    ; code in part B. When you are confident that your part B
    ; is working, you can then delete these seven lines. 
	/*ldi r17, high(TESTBUFFER)
	ldi r16, low(TESTBUFFER)
	push r17
	push r16
	rcall flash_message
    pop r16
    pop r17*/
   
; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION ********** 
; ***************************************************


; ################################################
; #### BEGINNING OF "TOUCH CAREFULLY" SECTION ####
; ################################################

; The only things you can change in this section is
; the message (i.e., MESSAGE01 or MESSAGE02 or MESSAGE03,
; etc., up to MESSAGE09).
;

	; encode a message
	;
	ldi r17, high(MESSAGE05 << 1)
	ldi r16, low(MESSAGE05 << 1)
	push r17
	push r16
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall encode_message
	pop r16
	pop r16
	pop r16
	pop r16

; ##########################################
; #### END OF "TOUCH CAREFULLY" SECTION ####
; ##########################################


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
	; display the message three times
	;
	ldi r18, 3
main_loop:
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall flash_message
	dec r18
	tst r18
	brne main_loop


stop:
	rjmp stop
; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================


; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION **** 
; ****************************************************


flash_message:
	rcall delay_long
	rcall delay_long
	rcall delay_long
	rcall delay_long			; add a delay between message cycles 
							;setup stack access
	.set PARAM_OFFSET = 10 
	push r17
	push r16
	push ZH
	push ZL
	push YH
	push YL

	in YH, SPH			;copy high byte to YH
	in YL, SPL			;copy low byte to YL

	ldd ZL, Y+PARAM_OFFSET
	ldd ZH, Y+PARAM_OFFSET+1

	thisMainLoop:
		ld r16, Z+			;load byte at Z into r16, then increment Z
		tst r16
		breq doneHere		;if 0, exit
		
		push r16			;save r16 before calling morse_flash
		call morse_flash
		pop r16				;restore r16
		rjmp thisMainLoop

	doneHere: 
						;restore registers
		pop YL
		pop YH
		pop ZL
		pop ZH
		pop r16
		pop r17
		ret




morse_flash:
    ; Save the initial value of r16, which contains the Morse code byte
    push r16
    push r17        ; For loop counter (sequence length)
    push r18        ; To hold the dot-dash sequence

    ; Check if r16 contains 0xFF (word gap)
    cpi r16, 0xff
    breq morse_flash_word_gap  

    ; Extract high nibble (sequence length) and low nibble (dot-dash sequence)
    swap r16                   ; Swap nibbles of r16
    mov r17, r16               ; Copy high nibble (sequence length) to r17
    mov r18, r16               ; Copy low nibble (dot-dash sequence) to r18
    andi r17, 0x0f             ; Mask out high nibble, keeping sequence length in r17
    andi r18, 0xf0             ; Mask out low nibble, leaving only dot-dash sequence
	mov r16, r17			   ; Set r16 to the length of the letter seq. thus allowing LEDs to work correctly

    ; Align the dot-dash sequence in r18 based on the sequence length
    cpi r17, 4
    breq aligned               ; If length is 4, no shift needed
    cpi r17, 3
    breq shift_once
    cpi r17, 2
    breq shift_twice
    cpi r17, 1
    breq shift_thrice
    rjmp aligned               ; Jump to aligned for any unhandled cases

shift_once:
    lsl r18                    ; Shift left by 1 to align
    rjmp aligned

shift_twice:
    lsl r18                    ; Shift left by 2 to align
    lsl r18
    rjmp aligned

shift_thrice:
    lsl r18                    ; Shift left by 3 to align
    lsl r18
    lsl r18

aligned:
    ; Now r18 is aligned with MSB as the first signal in the sequence

morse_flash_loop:
    tst r17                    ; Check if length counter is zero (end of sequence)
    breq end_morse_flash       ; If zero, end the loop

    ; Check the leftmost bit of the dot-dash sequence in r18
    sbrc r18, 7                ; Test if the top bit of r18 is set
    rcall dash                 ; If set, it’s a dash; call dash
    sbrs r18, 7                ; Test if the top bit of r18 is clear
    rcall dot                  ; If clear, it’s a dot; call dot

    ; Shift r18 left to bring the next bit into position
    lsl r18

    ; Decrement length counter and repeat loop if there are more symbols
    dec r17
    rjmp morse_flash_loop

end_morse_flash:
    ; Restore registers and return
    pop r18
    pop r17
    pop r16
    ret

; Handle a dot
dot:
    rcall leds_on
    rcall delay_short
    rcall leds_off
    rcall delay_long
    ret

; Handle a dash
dash:
    rcall leds_on
    rcall delay_long
    rcall leds_off
    rcall delay_long
    ret

; Handle word gap (0xFF byte)
morse_flash_word_gap:
    rcall delay_long
    rcall delay_long
    rcall delay_long
    pop r18
    pop r17
    pop r16
    ret



leds_on: ; LEDs turn on based on the length of the sequence of the letter. For example 'A' will have 2 LEDs since it is .- (2 sequence).
	push r16
    push r19            ; Control for PORTB LEDs
    push r20            ; Control for PORTL LEDs
	
	
    ldi r19, 0          ; Initialize PORTB (all LEDs off)
    ldi r20, 0          ; Initialize PORTL (all LEDs off)

    ; Directly set LEDs based on the value in r16
    cpi r16, 1
    brlo set_ports      ; If r16 < 1, skip to setting ports
    ori r20, 0x80       ; Turn on LED 1 (PORTL, bit 7)

    cpi r16, 2
    brlo set_ports      ; If r16 < 2, skip to setting ports
    ori r20, 0x20       ; Turn on LED 2 (PORTL, bit 5)

    cpi r16, 3
    brlo set_ports      ; If r16 < 3, skip to setting ports
    ori r20, 0x08       ; Turn on LED 3 (PORTL, bit 3)

    cpi r16, 4
    brlo set_ports      ; If r16 < 4, skip to setting ports
    ori r20, 0x02       ; Turn on LED 4 (PORTL, bit 1)

    cpi r16, 5
    brlo set_ports      ; If r16 < 5, skip to setting ports
    ori r19, 0x08       ; Turn on LED 5 (PORTB, bit 3)

    cpi r16, 6
    brlo set_ports      ; If r16 < 6, skip to setting ports
    ori r19, 0x02       ; Turn on LED 6 (PORTB, bit 1)

set_ports:
    sts S_PORTL, r20    ; Set PORTL with LED configuration
    sts S_PORTB, r19    ; Set PORTB with LED configuration

    pop r20
    pop r19
    pop r16
    ret



leds_off:
	push r16
    ldi r16, 0
    sts S_PORTB, r16    ; Turn off all PORTB LEDs
    sts S_PORTL, r16    ; Turn off all PORTL LEDs
    pop r16
    ret


encode_message:
    ; Save registers to maintain the stack frame
    .set OFFSET = 12

	push r17
	push r16
	push XH
	push XL
	push ZH
	push ZL
	push YH
	push YL

	in YH, SPH
	in YL, SPL

	ldd ZL, Y + OFFSET + 2 ; Z: THE MESSAGE
	ldd ZH, Y + OFFSET + 3
	ldd XL, Y + OFFSET  ; X: THE ADDRESS
	ldd XH, Y + OFFSET + 1      ; Load high byte of buffer address

	encode_loop:
			; Load a character from the message
		lpm r16, Z+
		tst r16
		breq encode_done

		push r16                ; Push the character onto the stack
		rcall letter_to_code    ; Convert character to Morse code; result in r0
		pop r16                 ; Clean up the stack after letter_to_code

		; Store the result (one-byte Morse code) in the buffer
		st X+, r0               ; Store r0 in buffer at X, then increment X

	    rjmp encode_loop        ; Repeat for the next character

encode_done:
	clr r0
	st x+, r0
    pop YL
	pop YH
	pop ZL
	pop ZH
	pop XL
	pop XH
	pop r16
	pop r17
	
	ret	


letter_to_code:
	.set OFFSET = 9 
    ; Save registers for stack frame
    push r16
    push r17
    push r18
    push r19
    push r20
    push r22
    push r23
    push ZH
    push ZL
    push YH
    push YL

    ; Load stack pointer into Y for stack frame
    in YH, SPH
    in YL, SPL

    ; Load base address of ITU_MORSE table into Z
    ldi ZH, high(ITU_MORSE << 1)
    ldi ZL, low(ITU_MORSE << 1)
    
    lpm r17, Z+              ; Load character from table into r17
    ldi r18, 0               ; Length counter for dots & dashes
    ldi r19, 0               ; Stores dot-dash pattern
    ldi r20, '-'             ; Dash character for comparison
    ldi r22, 7               ; Offset for 8-byte table entries
    clr r23                  ; Clear helper register for carry handling
    clr r0                   ; Clear return register

while_not_empty:
    cpi r17, 0               ; Check if end of table
    breq letter_return     ; If end, exit

    cp r16, r17              ; Compare input letter with table character
    breq if_equals           ; If match found, jump to process dots and dashes

    ; Z += 8 to move to the next entry
    add ZL, r22              ; Add 8 to ZL for next entry
    adc ZH, r23              ; Add carry to ZH
    lpm r17, Z+              ; Load next character into r17
    rjmp while_not_empty     ; Repeat until a match is found

if_equals:
    ; Load next symbol (dot or dash)
    lpm r17, Z+1
    cpi r17, 0               ; Check if end of dot-dash sequence
    breq letter_return     ; If zero, end of sequence

    ; Shift existing pattern left to make space for next bit
    lsl r19                  
    inc r18                  ; Increment length counter

    cp r17, r20              ; Compare current symbol with dash character
    breq is_dash
	rjmp if_equals 


is_dash:
    ori r19, 1    ; Continue with next symbol
	
	rjmp if_equals

letter_return: 
    clr r0                   ; Clear return register
    swap r18                 ; Move length to high nibble
    or r0, r18               ; Combine length with result
    or r0, r19               ; Combine pattern with result

    ; Check if character was a space (result zero means space)
    tst r0
    brne not_space
	ldi r18, 0xff
    or r0, r18             ; Set r0 to 0xff if it's a space

not_space:
    ; Restore registers
    pop YL
    pop YH
    pop ZL
    pop ZH
    pop r23
    pop r22
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    ret



; **********************************************
; **** END OF SECOND "STUDENT CODE" SECTION **** 
; **********************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

delay_long:
	rcall delay
	rcall delay
	rcall delay
	ret

delay_short:
	rcall delay
	ret

; When wanting about a 1/5th of second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit
	
	ldi r17, 0xff
delay_busywait_loop2:
	dec	r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret


ITU_MORSE: .db "A", ".-", 0, 0, 0, 0, 0
	.db "B", "-...", 0, 0, 0
	.db "C", "-.-.", 0, 0, 0
	.db "D", "-..", 0, 0, 0, 0
	.db "E", ".", 0, 0, 0, 0, 0, 0
	.db "F", "..-.", 0, 0, 0
	.db "G", "--.", 0, 0, 0, 0
	.db "H", "....", 0, 0, 0
	.db "I", "..", 0, 0, 0, 0, 0
	.db "J", ".---", 0, 0, 0
	.db "K", "-.-", 0, 0, 0, 0
	.db "L", ".-..", 0, 0, 0
	.db "M", "--", 0, 0, 0, 0, 0
	.db "N", "-.", 0, 0, 0, 0, 0
	.db "O", "---", 0, 0, 0, 0
	.db "P", ".--.", 0, 0, 0
	.db "Q", "--.-", 0, 0, 0
	.db "R", ".-.", 0, 0, 0, 0
	.db "S", "...", 0, 0, 0, 0
	.db "T", "-", 0, 0, 0, 0, 0, 0
	.db "U", "..-", 0, 0, 0, 0
	.db "V", "...-", 0, 0, 0
	.db "W", ".--", 0, 0, 0, 0
	.db "X", "-..-", 0, 0, 0
	.db "Y", "-.--", 0, 0, 0
	.db "Z", "--..", 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

MESSAGE01: .db "A A A", 0
MESSAGE02: .db "SOS", 0
MESSAGE03: .db "A BOX", 0
MESSAGE04: .db "DAIRY QUEEN", 0
MESSAGE05: .db "THE SHAPE OF WATER", 0, 0
MESSAGE06: .db "DEADPOOL AND WOLVERINE", 0, 0
MESSAGE07: .db "EVERYTHING EVERYWHERE ALL AT ONCE", 0
MESSAGE08: .db "O CANADA TERRE DE NOS AIEUX", 0
MESSAGE09: .db "HARD TO SWALLOW PILLS", 0

; First message ever sent by Morse code (in 1844)
MESSAGE10: .db "WHAT GOD HATH WROUGHT", 0


.dseg
BUFFER01: .byte 128
BUFFER02: .byte 128
TESTBUFFER: .byte 4

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================
