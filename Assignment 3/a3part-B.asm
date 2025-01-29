;
; a3part-B.asm
;
; Part B of assignment #3
;
;
; Student name: Lucas Hewgill
; Student ID: V01033481
; Date of completed work:
;
; **********************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2024-Nov-04)
;
; This skeleton of an assembly-language program is provided to help you 
; begin with the programming tasks for A#3. As with A#2 and A#1, there are
; "DO NOT TOUCH" sections. You are *not* to modify the lines within these
; sections. The only exceptions are for specific changes announced on
; Brightspace or in written permission from the course instruction.
; *** Unapproved changes could result in incorrect code execution
; during assignment evaluation, along with an assignment grade of zero. ***
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
; 
; (1) assembler direction setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants that may be used later in
;     the program
;
; (4) code for initial setup of the Analog-to-Digital Converter
;     (in the same manner in which it was set up for Lab #4)
;
; (5) Code for setting up three timers (timers 1, 3, and 4).
;
; After all this initial code, your own solutions's code may start
;

.cseg
.org 0
	jmp reset

; Actual .org details for this an other interrupt vectors can be
; obtained from main ATmega2560 data sheet
;
.org 0x22
	jmp timer1

; This included for completeness. Because timer3 is used to
; drive updates of the LCD display, and because LCD routines
; *cannot* be called from within an interrupt handler, we
; will need to use a polling loop for timer3.
;
; .org 0x40
;	jmp timer3

.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd.asm"

.cseg
#define CLOCK 16.0e6
#define DELAY1 0.01
#define DELAY3 0.1
#define DELAY4 0.5

#define BUTTON_RIGHT_MASK 0b00000001	
#define BUTTON_UP_MASK    0b00000010
#define BUTTON_DOWN_MASK  0b00000100
#define BUTTON_LEFT_MASK  0b00001000

#define BUTTON_RIGHT_ADC  0x032
#define BUTTON_UP_ADC     0x0b0   ; was 0x0c3
#define BUTTON_DOWN_ADC   0x160   ; was 0x17c
#define BUTTON_LEFT_ADC   0x22b
#define BUTTON_SELECT_ADC 0x316

.equ PRESCALE_DIV=1024   ; w.r.t. clock, CS[2:0] = 0b101

; TIMER1 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))
.if TOP1>65535
.error "TOP1 is out of range"
.endif

; TIMER3 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

; TIMER4 is a 16-bit timer. If the Output Compare value is
; larger than what can be stored in 16 bits, then either
; the PRESCALE needs to be larger, or the DELAY has to be
; shorter, or both.
.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif

reset:
; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION ****
; ***************************************************

; Anything that needs initialization before interrupts
; start must be placed here.
.def DATAH=r25  ;DATAH:DATAL  store 10 bits data from ADC
.def DATAL=r24
.def BOUNDARY_H = r1
.def BOUNDARY_L = r0
.def BOUNDARY_BH = r3
.def BOUNDARY_BL = r2

.equ ADCSRA_BTN=0x7A
.equ ADCSRB_BTN=0x7B
.equ ADMUX_BTN=0x7C
.equ ADCL_BTN=0x78
.equ ADCH_BTN=0x79

ldi r16, low(RAMEND)
mov BOUNDARY_L, r21
ldi r16, high(RAMEND)
mov BOUNDARY_H, r21

; ***************************************************
; ******* END OF FIRST "STUDENT CODE" SECTION *******
; ***************************************************

; =============================================
; ====  START OF "DO NOT TOUCH" SECTION    ====
; =============================================

	; initialize the ADC converter (which is needed
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer 1 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16

	; Timer 1 is for sampling the buttons at 10 ms intervals.
	; We will use an interrupt handler for this timer.
	ldi r17, high(TOP1)
	ldi r16, low(TOP1)
	sts OCR1AH, r17
	sts OCR1AL, r16
	clr r16
	sts TCCR1A, r16
	ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
	sts TCCR1B, r16
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; Timer 3 is for updating the LCD display. We are
	; *not* able to call LCD routines from within an 
	; interrupt handler, so this timer must be used
	; in a polling loop.
	ldi r17, high(TOP3)
	ldi r16, low(TOP3)
	sts OCR3AH, r17
	sts OCR3AL, r16
	clr r16
	sts TCCR3A, r16
	ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
	sts TCCR3B, r16
	; Notice that the code for enabling the Timer 3
	; interrupt is missing at this point.

	; Timer 4 is for updating the contents to be displayed
	; on the top line of the LCD.
	ldi r17, high(TOP4)
	ldi r16, low(TOP4)
	sts OCR4AH, r17
	sts OCR4AL, r16
	clr r16
	sts TCCR4A, r16
	ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
	sts TCCR4B, r16
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

	sei

; =============================================
; ====    END OF "DO NOT TOUCH" SECTION    ====
; =============================================

; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION ****
; ****************************************************

rcall lcd_init

start: ; Polling loop for Timer 3
    in r16, TIFR3         ; Read Timer 3 Interrupt Flag Register
    sbrs r16, OCF3A       ; Skip next instruction if Output Compare Flag is set
    rjmp start            ; Repeat polling if flag is not set

    ldi r16, (1 << OCF3A) ; Load mask to clear the Output Compare Flag
    out TIFR3, r16        ; Clear the Output Compare Flag
    rjmp timer3           ; Jump to Timer 3 handler

stop:
	rjmp stop

timer1: 
;partA
	push r16
	lds r16, SREG
	push r16
	push DATAL
	push DATAH
	push BOUNDARY_L
	push BOUNDARY_H
	push r23
	push BOUNDARY_BL
	push BOUNDARY_BH
	push r17

	lds	r16, ADCSRA_BTN	
	ori r16, 0x40 ; 0x40 = 0b01000000
	sts	ADCSRA_BTN, r16

wait: ; Wait for ADC conversion to complete
    lds r16, ADCSRA_BTN
    andi r16, 0x40        ; Check ADSC bit
    brne wait             ; Wait until ADSC is cleared

    ; Read ADC result into DATAH:DATAL
    lds DATAL, ADCL_BTN
    lds DATAH, ADCH_BTN

    ; Load boundary for button select detection
    ldi r16, low(BUTTON_SELECT_ADC)
    mov BOUNDARY_L, r16
    ldi r16, high(BUTTON_SELECT_ADC)
    mov BOUNDARY_H, r16

    clr r23               ; Clear temporary register r23
    cp DATAL, BOUNDARY_L  ; Compare ADC low byte with boundary low byte
    cpc DATAH, BOUNDARY_H ; Compare ADC high byte with boundary high byte
    brsh btn_pressed      ; Branch if ADC value >= boundary
    ldi r23, 1            ; Set r23 to 1 (button not pressed)

btn_pressed:	
		sts BUTTON_IS_PRESSED, r23 ; Store r23 into BUTTON_IS_PRESSED

											;partB
checkR:		;check the ADC value range 
		ldi r16, low(BUTTON_RIGHT_ADC)
		mov BOUNDARY_BL, r16
		ldi r16, high(BUTTON_RIGHT_ADC)
		mov BOUNDARY_BH, r16
		cp DATAL, BOUNDARY_BL
		cpc DATAH, BOUNDARY_BH
		brlo lcd_right

checkU:
		ldi r16, low(BUTTON_UP_ADC)
		mov BOUNDARY_BL, r16
		ldi r16, high(BUTTON_UP_ADC)
		mov BOUNDARY_BH, r16
		cp DATAL, BOUNDARY_BL
		cpc DATAH, BOUNDARY_BH
		brlo lcd_up

checkD:
		ldi r16, low(BUTTON_DOWN_ADC)
		mov BOUNDARY_BL, r16
		ldi r16, high(BUTTON_DOWN_ADC)
		mov BOUNDARY_BH, r16
		cp DATAL, BOUNDARY_BL
		cpc DATAH, BOUNDARY_BH
		brlo lcd_down

checkL:
		ldi r16, low(BUTTON_LEFT_ADC)
		mov BOUNDARY_BL, r16
		ldi r16, high(BUTTON_LEFT_ADC)
		mov BOUNDARY_BH, r16
		cp DATAL, BOUNDARY_BL
		cpc DATAH, BOUNDARY_BH
		brlo lcd_left

lcd_right:		;load each letters to LAST_BUTTON_PRESSED
		ldi r17, 'R'
		sts LAST_BUTTON_PRESSED, r17
		rjmp endT1

lcd_up:
		ldi r17, 'U'
		sts LAST_BUTTON_PRESSED, r17
		rjmp endT1

lcd_down:
		ldi r17, 'D'
		sts LAST_BUTTON_PRESSED, r17
		rjmp endT1

lcd_left:
		ldi r17, 'L'
		sts LAST_BUTTON_PRESSED, r17
		rjmp endT1

endT1:
	pop r17
	pop BOUNDARY_BH
	pop BOUNDARY_BL
	pop r23
	pop BOUNDARY_H
	pop BOUNDARY_L
	pop DATAH
	pop DATAL
	pop r16
	sts SREG, r16
	pop r16

	reti

timer3:
									;partA
	push r16
	push r17
	push r18
	push r19
	push r20

	ldi r16, 1
	ldi r17, 15
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	clr r18
	lds r18, BUTTON_IS_PRESSED
	cpi r18, 0x01
	breq star_on

dash_on:
	ldi r18, '-'
	push r18
	rcall lcd_putchar
	pop r18
	rjmp endT3

star_on:
	ldi r18, '*'
	push r18
	rcall lcd_putchar
	pop r18

								;partB
direction_on:
	ldi r16, 1
	ldi r17, 0
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	clr r19
	lds r19, LAST_BUTTON_PRESSED
	ldi r20, ' '

	cpi r19, 'L'
	breq left_on

	cpi r19, 'D'
	breq down_on

	cpi r19, 'U'
	breq up_on

	cpi r19, 'R'
	breq right_on

left_on:
	push r19	;L
	rcall lcd_putchar
	pop r19
	push r20	;D
	rcall lcd_putchar
	pop r20
	push r20	;U
	rcall lcd_putchar
	pop r20
	push r20	;R
	rcall lcd_putchar
	pop r20
	rjmp endT3

down_on:
	push r20	;L
	rcall lcd_putchar
	pop r20
	push r19	;D
	rcall lcd_putchar
	pop r19
	push r20	;U
	rcall lcd_putchar
	pop r20
	push r20	;R
	rcall lcd_putchar
	pop r20
	rjmp endT3

up_on:
	push r20	;L
	rcall lcd_putchar
	pop r20
	push r20	;D
	rcall lcd_putchar
	pop r20
	push r19	;U
	rcall lcd_putchar
	pop r19
	push r20	;R
	rcall lcd_putchar
	pop r20
	rjmp endT3

right_on:
	push r20	;L
	rcall lcd_putchar
	pop r20
	push r20	;D
	rcall lcd_putchar
	pop r20
	push r20	;U
	rcall lcd_putchar
	pop r20
	push r19	;R
	rcall lcd_putchar
	pop r19

endT3:
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	rjmp start

; timer3:
;
; Note: There is no "timer3" interrupt handler as you must use
; timer3 in a polling style (i.e. it is used to drive the refreshing
; of the LCD display, but LCD functions cannot be called/used from
; within an interrupt handler).


timer4:
	reti


; ****************************************************
; ******* END OF SECOND "STUDENT CODE" SECTION *******
; ****************************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

; r17:r16 -- word 1
; r19:r18 -- word 2
; word 1 < word 2? return -1 in r25
; word 1 > word 2? return 1 in r25
; word 1 == word 2? return 0 in r25
;
compare_words:
	; if high bytes are different, look at lower bytes
	cp r17, r19
	breq compare_words_lower_byte

	; since high bytes are different, use these to
	; determine result
	;
	; if C is set from previous cp, it means r17 < r19
	; 
	; preload r25 with 1 with the assume r17 > r19
	ldi r25, 1
	brcs compare_words_is_less_than
	rjmp compare_words_exit

compare_words_is_less_than:
	ldi r25, -1
	rjmp compare_words_exit

compare_words_lower_byte:
	clr r25
	cp r16, r18
	breq compare_words_exit

	ldi r25, 1
	brcs compare_words_is_less_than  ; re-use what we already wrote...

compare_words_exit:
	ret

.cseg
AVAILABLE_CHARSET: .db "0123456789abcdef_", 0


.dseg

BUTTON_IS_PRESSED: .byte 1			; updated by timer1 interrupt, used by LCD update loop
LAST_BUTTON_PRESSED: .byte 1        ; updated by timer1 interrupt, used by LCD update loop

TOP_LINE_CONTENT: .byte 16			; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHARSET_INDEX: .byte 16		; updated by timer4 interrupt, used by LCD update loop
CURRENT_CHAR_INDEX: .byte 1			; ; updated by timer4 interrupt, used by LCD update loop


; =============================================
; ======= END OF "DO NOT TOUCH" SECTION =======
; =============================================


; ***************************************************
; **** BEGINNING OF THIRD "STUDENT CODE" SECTION ****
; ***************************************************

.dseg

; If you should need additional memory for storage of state,
; then place it within the section. However, the items here
; must not be simply a way to replace or ignore the memory
; locations provided up above.


; ***************************************************
; ******* END OF THIRD "STUDENT CODE" SECTION *******
; ***************************************************
