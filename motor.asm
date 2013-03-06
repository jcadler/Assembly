
;    Filename:	    motor.asm                                         *
;    Date:                                                            *
;    File Version:                                                    *
;                                                                     *
;    Author:                                                          *
;    Company:                                                         *
;                                                                     * 
;                                                                     *
;**********************************************************************
;                                                                     *
;    Files Required: P16F690.INC                                      *
;                                                                     *
;**********************************************************************
;                                                                     *
;    Notes:                                                           *
;                                                                     *
;**********************************************************************


	list		p=16f690		; list directive to define processor
	#include	<P16F690.inc>		; processor specific variable definitions
	
	__CONFIG    _CP_OFF & _CPD_OFF & _BOR_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF


; '__CONFIG' directive is used to embed configuration data within .asm file.
; The labels following the directive are located in the respective .inc file.
; See respective data sheet for additional information on configuration word.






;***** VARIABLE DEFINITIONS
w_temp		EQU	0x7D			; variable used for context saving
status_temp	EQU	0x7E			; variable used for context saving
pclath_temp	EQU	0x7F			; variable used for context saving




;**********************************************************************
	ORG		0x000			; processor reset vector
  	goto		main			; go to beginning of program


	ORG		0x004			; interrupt vector location
	movwf		w_temp			; save off current W register contents
	movf		STATUS,w		; move status register into W register
	movwf		status_temp		; save off contents of STATUS register
	movf		PCLATH,w		; move pclath register into W register
	movwf		pclath_temp		; save off contents of PCLATH register
	movf PORTA,w	;move the PORTA register to the working register
	movwf h'30'		;move the value of the PORTA register to address h'30
	movlw b'00001111'	;set the first four PORTC pins to up (turns on LEDs)
	movwf PORTC
switchloop
	movlw b'00100000' ;turn on the motor
	movwf PORTA
	call delay1	;wait a second
	clrf PORTA	;turn off the motor
	call delay1	;wait a second
	btfss PORTA,4	;if the switch is not pushed down then continue the PWM
		goto switchloop
	movlw d'50'		;the rest of the interreupt is set up to turn right so it keeps one motor running constantly while the other turns off for a bit
	movwf h'23'
idelay
	movlw d'10'
	movwf h'24'
move
	movlw b'00100001'
	movwf PORTA
	call delay1
	movlw b'00000001'
	movwf PORTA
	call delay1
idloop
	decfsz h'24'
		goto move
	decfsz h'23'
		goto idelay
	bcf INTCON,0
	movf h'30',w
	movwf PORTA
	clrf PORTC
	movf		pclath_temp,w		; retrieve copy of PCLATH register
	movwf		PCLATH			; restore pre-isr PCLATH register contents	
	movf		status_temp,w		; retrieve copy of STATUS register
	movwf		STATUS			; restore pre-isr STATUS register contents
	swapf		w_temp,f
	swapf		w_temp,w		; restore pre-isr W register contents
	retfie					; return from interrupt


main
	bcf INTCON,RABIF		;reset interrupt
	bsf STATUS,RP0		;bank 1
	movlw b'00010000'		;set RA4 as input
	movwf TRISA
	clrf TRISC
	bcf OPTION_REG,7 	;set pull-up resistors
	bsf WPUA,4		;turn on pull-up resistor on RA4
	bsf IOCA,4		;turn on Interrupt On Change for RA4
	bcf STATUS,RP0	;bank 2
	bsf STATUS,RP1
	clrf ANSEL		;disable A/D converters
	clrf ANSELH
	bcf STATUS,RP1		;Bank 0
	clrf PORTA		;reset RA pins
	bsf INTCON,GIE		;turn on general interrupts
	bsf INTCON,RABIE		;turn on RA/B interrupts
loop
	movlw b'00100000'		;PWM 2 ms intervals
	movwf PORTA
	call delay1
	call delay1
	clrf PORTA
	call delay1
	call delay1
	goto loop
delay1		;delay for 1 ms
	movlw d'17'
	movwf h'20'
delay2
	movlw d'100'
	movwf h'21'
dloop
	decfsz h'21'
		goto dloop
	decfsz h'20'
		goto delay2	
	return 	
delays
	movlw d'26'
	movwf h'22'
delayOs
	movlw d'255'
	movwf h'20'
delayls
	movlw d'255'
	movwf h'21'
dloops
	decfsz h'21'
		goto dloops
	decfsz h'20'
		goto delayls	
	decfsz h'22'
		goto delayOs
	return 
	

	ORG	0x2100				; data EEPROM location
	DE	1,2,3,4				; define first four EEPROM locations as 1, 2, 3, and 4




	END                       ; directive 'end of program'


