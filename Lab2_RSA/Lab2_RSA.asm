/* 
	Name: Ronney Sanchez
	Date: 11/22/16
	Course: CTE210 Microcomputers
	Program: Lab 2 Delay Function and Count Down
	Description: This program store a ten element array of 8 bit instructions of how to display a number to a 7 segment display and calls the display
	function with a delay function to count down from 9 to 0 by the number of seconds.

	comment out in atmel studio
	.device ATmega328P
	.equ INT_VECTORS_SIZE	= 52   size in words

	 timer stuff
	.equ TCNT0	= 0x26
	.equ TCCR0B	= 0x25
	.equ TIMSK0	= 0x6e

	 output stuff
	.equ PORTD 	= 0x0b
	.equ DDRD 	= 0x0a
	.equ PORTB 	= 0x05
	.equ DDRB 	= 0x04
*/

.def overflows = R17
.def temp = R16

.org 0 ; reset instruction at $0
.device ATmega328P ;The device that we are using is the ATmega328P
.equ size = 10 ;Equate the size to 10
.dseg ;Data segment to allocate array memory
myArray: .byte size ;Allocate 10 bytes for the array

.cseg ;Current segment as code
.org 0 ;Starting at address 0
rjmp setup ;Jump to the setup


.org 0x0020            ;overflow interrupt handler at $20 - see data sheet
rjmp overflow_handler  ;jump to handler

.org INT_VECTORS_SIZE  ;start the program after the interrupt table

setup:
	ldi temp, 0b00000001  ; set the Timer Overflow Interrupt Enabled bit(TOIE0)
	sts TIMSK0, temp      ; of the Timer Interrupt Mask Register (TIMSK0)

	sei                   ; enable global interrupts
                        ; this must be disabled when you write to SPL/SPH
                        ; this is discussed in CH6 of the text

	ldi temp,  0b00000101 ; set the Clock Selector Bits CS00, CS01, CS02 to 101
	out TCCR0B, temp      ; Timer Counter0, TCNT0 in to FCPU/1024 (see data sheet)
                        ; FCPU is 16Mhz that is 16000000 cycles per sec
                        ; 16000000/1024 = 15625 "ticks" per second
                        ; timer "ticks" are stored in an 8 bit register
                        ; it will overflow after 256 "ticks"
                        ; 15625/256 = 61.03 about 61 overflows per second

	clr temp
	out TCNT0, temp       ;initialize Timer Counter0 to 0

	.def limit = r19 ;Define the limit as register 19
	.def number = r25 ;Define the number register as register 25
	ldi YL, low(myArray) ;Load the low byte of the array to the low Y register
	ldi YH, high(myArray) ;Load the high byte of the array to the high Y register
	ldi limit, size ;Load the size of the array to the limit register

	ldi temp, 0b01111110 ;Load the seven segment display instruction for 0 to temp
	st Y, temp ;Store the instruction to the Y register

	adiw Y, 1 ;Move the Y pointer by 1 unit

	ldi temp, 0b00001100 ;Load the seven segment display instruction for 1 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b10110110 ;Load the seven segment display instruction for 2 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b10011110 ;Load the seven segment display instruction for 3 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b11001100 ;Load the seven segment display instruction for 4 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b11011010 ;Load the seven segment display instruction for 5 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b11111010 ;Load the seven segment display instruction for 6 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b00001110 ;Load the seven segment display instruction for 7 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b11111110 ;Load the seven segment display instruction for 8 to temp
	st Y+, temp ;Store the instruction to the Y register and post increment pointer

	ldi temp, 0b11001110 ;Load the seven segment display instruction for 9 to temp
	st Y, temp ;Store the instruction to the Y register

	ldi number, 9 ;Load 9 to the number register
	ldi temp, 0xFF ;Load all 1s to temp
	out DDRD, temp ;Output all the 1s to the Data Direction Register in Port D
	
	rjmp main ;Jump to main

main:
				;Turn ON LED
	rcall delay ;call the delay function
	rcall display ;Call the display function
				
    ;TURN OFF LED
	rcall delay ;delay again

	subi number, 1 ; Subtract 1 from the number register
	cpi number, -1 ;Compare the number register with -1
	breq setup ;Branch to setup if equal to -1
 
	rjmp main ;loop to main

;delay function
delay:
	clr overflows          ; set overflows to 0
delay_loop:
	cpi overflows, 38   	 ; how many ticks to wait? delay here until then
	brne delay_loop     	 ; loop here and keep checking ticks
	ret                 	 ; if the number of ticks is met, return to caller

;runs when the counter overflows
overflow_handler:
   inc overflows          ; add 1 to overflows register  (number of overflows)
   cpi overflows, 61      ; compare with 61 (overflows)
   brne overflow_return   ; if not 61 overflows, just return from the interrupt
   clr overflows          ; otherwise reset the counter to zero
overflow_return:
   reti                   ; return from interrupt

display:
	ldi YL, low(myArray) ;Move the Y pointer to the start of the array
	ldi YH, high(myArray)
	add YL, number ;move the Y pointer the number units to the right
	ldi temp, 0 ;Load 0 to temp
	adc YH, temp ;Add the value with the carry to the high byte of Y
	ld temp, Y ;Y now points to the segment
	out PORTD, temp ;Output the instuction from temp to PORT D
	ret ;Return to the caller