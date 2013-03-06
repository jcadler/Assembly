
	list		p=16f690		; list directive to define processor
	#include	<P16F690.inc>		; processor specific variable definitions
	
	__CONFIG    _CP_OFF & _CPD_OFF & _BOR_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF
;***** VARIABLE DEFINITIONS
w_temp		EQU	0x7D			; variable used for context saving
status_temp	EQU	0x7E			; variable used for context saving
pclath_temp	EQU	0x7F			; variable used for context saving
count EQU h'30'		; variable used to store final count from timer
multi EQU h'31'		; variable used to store the number of overflows
distancedecipnt EQU h'32'
distance EQU h'33'		; low end of the distance word
distance_h EQU h'34'	; high end of the distance word

;**********************************************************************
	ORG		0x000			; processor reset vector
  	goto		main			; go to beginning of program


	ORG		0x004			; interrupt vector location
	movwf		w_temp			; save off current W register contents
	movf		STATUS,w		; move status register into W register
	movwf		status_temp		; save off contents of STATUS register
	movf		PCLATH,w		; move pclath register into W register
	movwf		pclath_temp		; save off contents of PCLATH register

	movf		pclath_temp,w		; retrieve copy of PCLATH register
	movwf		PCLATH			; restore pre-isr PCLATH register contents	
	movf		status_temp,w		; retrieve copy of STATUS register
	movwf		STATUS			; restore pre-isr STATUS register contents
	swapf		w_temp,f
	swapf		w_temp,w		; restore pre-isr W register contents
	retfie					; return from interrupt


main
	bcf STATUS,RP0 ;Bank 0
	bsf STATUS,RP1 ;Bank 2
	clrf ANSEL ;Turn off A/D converters
	clrf ANSELH	
	bcf STATUS,RP1	;Bank 1
	bsf STATUS,RP0
	bcf INTCON,7
	clrf TRISA
	clrf TRISC
	bcf OPTION_REG,7
	clrf WPUA
	bsf WPUA,2
	bcf STATUS,RP0
init
	clrf PORTA	;Initialize A pins
	clrf PORTC	;Initialize C pins
	clrf count	;Initialize count register
	clrf multi	;Initialize multi register
	call pulse	;Pulse ultrasonic sensor
	bsf STATUS,RP0	;Bank 1
	movlw b'00010000'
	movwf TRISA
	bcf STATUS,RP0	;Bank 0
	bcf STATUS,Z	;Initialize Z 
checkpout
	btfss PORTA,4	;Check for Ultrasonic high input
		goto checkpout	;loop until high
	bsf STATUS,RP0	;Bank 1
	bcf OPTION_REG,5	;Enable 8-bit counter
	movwf TMR0	;set 8-bit counter to 5
	bcf STATUS,RP0
	nop
	nop
checkpin
	btfsc INTCON,2	;check if TMR0 has overflowed
		call overflow	;if overflow increment number of overflows and clear interrupt bit
	btfsc PORTA,4	;check if pulse returned
		goto checkpin	;if not then loop
	movf TMR0,w	;if pulse return then save TMR0 value
	movwf count	;save in count register
initcalc
	bcf STATUS,Z	;initialize Z flag
	movlw d'0'	;initialize W register
	movlw distance ;set indirect address to the location of the distance register
	movwf FSR
	clrf INDF	;clr the distance register
	incf FSR
	clrf INDF	;clr the distance_h register
	decf FSR
	bcf STATUS,Z	;init Z flag
	movlw d'7'	;distance traveled in one cycle (I am unsure as to the distance this is, but checking my math I am under the assumption this is the wrong value
calcmulti	
	decf multi	;decrement the overflow register
	btfsc STATUS,Z	;if it is zero then finish calculating multi section
		goto endcalcmulti
	incf INDF,f	;increment the distance register
	btfsc STATUS,Z	;if it overflows then call the distanceoverflow method
		call distanceoverflow
	bcf STATUS,Z	;clear zero bit
	addwf distancedecipnt,f	;add the distance traveled to the decimal number
	btfsc STATUS,Z	;if it overflowed then call the decioverflow method
		call decioverflow
	bcf STATUS,Z	;clear zero bit
	goto calcmulti	;repeat until multi is zero
calcdeci
	movf distancedecipnt,w
	sublw d'10'
	btfsc STATUS,Z
		goto endcalcmulti
	incf INDF,f
	goto calcdeci
endcalcmulti
	bcf STATUS,Z	;clear z flag
	addwf INDF	;add a final distance to the 
	btfsc STATUS,Z ;if it zeros the increment the indirect address
		incf FSR
	bcf STATUS,C ;clear the carry flag
	movlw d'145'	;the number of cycles of TMR0 which will equate to a significant distance
calccount
	bcf STATUS,C	;clear the carry bit
	subwf count,f	;subtract the value from the count register
	btfsc STATUS,C	;if the value went below 0 then continue end the calccount
		goto endcalccount
	incf INDF,f		;for every time you can subtract the value increment the distance register
	goto calccount	;repeat until calc is 0
endcalccount
	bcf STATUS,C	;clear the carry register
	movlw distance	;move the distance address to the indirect addressing register
	movwf FSR		
displaydistance
	movlw b'00001111'	;mask bottom nibble of multi
	andwf INDF,w
	movwf PORTC	;display on PORTC LEDs
	call delays
	call delays
	clrf PORTC
	call delays
	swapf INDF,f	;swap bottom and top nibbles of multi
	movlw b'00001111'
	andwf INDF,w	;mask bottom(top) nibble of multi
	movwf PORTC	;display on PORTC LEDs
	call delays	;wait two seconds
	call delays
	clrf PORTC	;display 0
	call delays	;wait a second
	btfsc STATUS,C	;if the carry flag is set then reset
		goto init	
	bsf STATUS,C	;set the carry flag
	incf FSR	;move to distance_h
	goto displaydistance	;repeat for high byte of the word
noin
	movlw b'00001111'
	movwf PORTC
	call delays
	call delays
	clrf PORTC
	call delays
	call delays
	goto init

delay5mics
	nop
	nop
	movlw d'6' 
	movwf h'21'
loop
	decfsz h'21'
		goto loop
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

pulse
	bsf PORTA,4 ;RA4 high
	call delay5mics	;wait 5 microseconds
	clrf PORTA
	return 
	
overflow
	incf multi
	bcf INTCON,2
	return

distanceoverflow
	movlw d'255'
	movwf INDF
	incf FSR
	movlw d'17'
	addwf FSR,f
	return

decioverflow
	movlw d'36'
	addwf INDF,f
	movlw d'2'
	movwf distancedecipnt
	return

	ORG	0x2100				; data EEPROM location
	DE	1,2,3,4				; define first four EEPROM locations as 1, 2, 3, and 4




	END                       ; directive 'end of program'


