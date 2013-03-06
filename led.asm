                                                                   
;    Filename:	    led.asm                                           *
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


; isr code can go here or be located as a call subroutine elsewhere

	movf		pclath_temp,w		; retrieve copy of PCLATH register
	movwf		PCLATH			; restore pre-isr PCLATH register contents	
	movf		status_temp,w		; retrieve copy of STATUS register
	movwf		STATUS			; restore pre-isr STATUS register contents
	swapf		w_temp,f
	swapf		w_temp,w		; restore pre-isr W register contents
	retfie					; return from interrupt


main
	bsf STATUS,RP0
	clrf TRISC
	bcf STATUS,RP0
	call init
loop
	movlw b'0001111'
	movwf PORTC
	call delay	
	clrf PORTC
	call delay
	goto main

delay
	movlw d'26'
	movwf h'22'
delay2
	movlw d'255'
	movwf h'20'
delay1
	movlw d'255'
	movwf h'21'
dloop
	decfsz h'21'
		goto dloop
	decfsz h'20'
		goto delay1	
	decfsz h'22'
		goto delay2
	return 
init
	clrf PORTC
	bsf STATUS,RP1
	movlw b'11111111'
	movwf ANSEL
	movlw b'00001111'
	movwf ANSELH
	bcf STATUS,RP1
	return

	ORG	0x2100				; data EEPROM location
	DE	1,2,3,4				; define first four EEPROM locations as 1, 2, 3, and 4




	END                       ; directive 'end of program'

