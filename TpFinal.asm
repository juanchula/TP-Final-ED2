list    p = 16f887
include <p16f887.inc>
	
__CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _MCLRE_ON
	
W_TEMP	    EQU	    0x20	
STATUS_TEMP EQU	    0x21
FSR_TEMP    EQU	    0x22
CONDICION   EQU	    0x23
CANTLED     EQU	    0x24
RESULTADO   EQU	    0x25
CONDEUSAR   EQU	    0x26
CONTADOR    EQU	    0x27
LED	    EQU	    0x28
	    
org	0x00
goto	SETEO
	
org	0x4
goto	INTERRUPCION
	
org	0x5
SETEO   
    
;====================================================================
    ;Seteo de puertos
;====================================================================
	BANKSEL 	TRISD
	CLRF    	TRISD		;Seteo puerto C como salida (leds)
	MOVLW   	b'00000001'		
	MOVWF    	TRISA		;Seteo RA0 como entrada
	BSF	    	STATUS, RP1
	BSF	    	STATUS, RP0	; Banco 11:3
	BSF     	ANSEL,	ANS0	; Seteo RA0 como entrada analogical 	
    
;====================================================================
    ;Configuro del ADC
;====================================================================
	BANKSEL	    ADCON1
	BCF	    ADCON1,ADFM		; Resultado justificado a la izquierda
	BCF	    ADCON1,VCFG0	; Seteo Vref+ como Vdd
	BCF	    ADCON1,VCFG1	; Seteo Vref- como fuente interna (masa)
	BANKSEL	    ADCON0
	BCF	    ADCON0,CHS0		; Selecciono como canal de entrada
	BCF	    ADCON0,CHS1		; para el ADC el pin ANS0 (RA0)
	BCF	    ADCON0,CHS2
	BCF	    ADCON0,CHS3
	BSF	    ADCON0,ADCS0	; Selecciono Frc como clock del ADC
	BCF	    ADCON0,ADCS1	; Fosc/8
	BSF	    ADCON0,ADON		; Activo el modulo ADC
 
;====================================================================
    ;Configuro TMR0
;====================================================================
	BANKSEL	    OPTION_REG
	BCF	    OPTION_REG,T0CS	; TOCS = 0  Utilizo el clock interno
	BCF	    OPTION_REG,T0SE	; TOSE = 0  Activo por flanco de subida
	BCF	    OPTION_REG,PSA	; PSA = 0   Activo el prescaler para TMR0
	BSF	    OPTION_REG,PS2	; CONFIGURO EL PRESCALER 1:256
	BSF	    OPTION_REG,PS1	; TMR=61 da 50ms, 10 veces, 0,5s
	BSF	    OPTION_REG,PS0	;
   
;====================================================================
    ;IE
;====================================================================
	BANKSEL	    PIE1
	BCF	    PIE1,ADIE		; Deshabilito las int por Receptor ADC
	BSF	    INTCON,PEIE		; Habilito las int por Perifericos
	BANKSEL	    PIR1
	BCF	    PIR1, ADIF		; Limpio flag de int de ADC
    
;====================================================================
    ;Inicializacon variables de control
;====================================================================
	CLRF	    PORTD
	CLRF	    CONDICION		; Establezco condicion en cero (Aun no hay dato para procesar)
	MOVLW	    D'01'		
        MOVWF	    CONDEUSAR		; Establezco condicion de eusar en uno (Listo para usar)
        MOVLW	    D'61'
        MOVWF	    TMR0		; Cargo el valor de TMR0
	BSF	    INTCON,T0IE 	; Se habilita interrupción por desbordamiento de TIMER0
        BCF	    INTCON,T0IF 	; Se limpia bandera de interrucion por TIMER0
        BSF	    INTCON,GIE		; Habilito las int Globales
    

    
PROGRAMA
	BTFSS	    CONDICION,0
	GOTO	    $-1
	
;====================================================================
    ;Calculo la cantidad de leds a encender
;====================================================================
ACTLEDS
	CLRF	    CONDICION
	CLRF	    CANTLED
	
	MOVLW	    D'28'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
	MOVLW	    D'56'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
	MOVLW	    D'84'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    LED,F
	
	MOVLW	    D'112'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
	MOVLW	    D'140'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
	MOVLW	    D'168'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
	MOVLW	    D'196'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
	MOVLW	    D'224'
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	GOTO	    MOSTRARLED
	INCF	    CANTLED,F
	
MOSTRARLED
	MOVF	    CANTLED,F
	CALL	    TABLA
	MOVWF	    PORTD
	GOTO	    PROGRAMA
	
TABLA
	ADDWF	    PCL,F		; suma a PC el valor del dígito
	RETLW	    B'00000000'
	RETLW	    B'00000001'
	RETLW	    B'00000011'
	RETLW	    B'00000111'
	RETLW	    B'00001111'
	RETLW	    B'00011111'
	RETLW	    B'00111111'
	RETLW	    B'01111111'
	RETLW	    B'11111111'

	
;====================================================================
    ;Subrutina de interrupcion
;====================================================================
INTERRUPCION
	MOVWF	    W_TEMP		; MOVWF no modifica STATUS. GUARDO CONTEXTO
	SWAPF	    STATUS, W		; SWAPF para mover f a W sin modificar STATUS
	MOVWF	    STATUS_TEMP		; Se guarda contexto: STATUS
	
	BTFSC	    INTCON,T0IF		; Interrumpió TIMER0?
	CALL	    ISTIMER		; Si T0IF está en 1 fue TIMER0 y llamo a ISTIMER
	BTFSC	    INTCON,ADIF		; Interrumpió ADC?
	CALL	    ISADC		; Si ADIF está en 1 fue ADC y llamo a ISADC
	
	SWAPF	    STATUS_TEMP, W	; Se recupera el contexto
	MOVWF	    STATUS
	SWAPF	    W_TEMP, F
	SWAPF	    W_TEMP, W
	RETFIE
	
ISTIMER
	BCF	    INTCON,T0IF 	; Se limpia bandera de interrucion por TIMER0
	MOVLW	    D'61'
	MOVWF	    TMR0
	INCF	    CONTADOR,F
	MOVLW	    D'10'
	SUBWF	    CONTADOR,W
	BTFSS	    STATUS,Z
	RETURN
	BSF	    ADCON0,GO		; Se inicia la convercion
	BSF	    PIE1,ADIE		; Habilito las int por Receptor ADC
	BCF	    INTCON,T0IE 	; Se deshabilita interrupción por desbordamiento de TIMER0
	RETURN
	
ISADC
	BCF	    PIR1, ADIF		; Limpio flag de int de ADC
	BANKSEL	    PIE1
	BCF	    PIE1,ADIE		; Deshabilito las int por Receptor ADC
	BANKSEL	    PORTD
	MOVF	    ADRESH,W
	MOVWF	    RESULTADO		; Movemos el valor obtenido a resultado
	MOVLW	    D'01'
	MOVWF	    CONDICION		; Seteo condicion en 1 (Nuevo valor a procesar)
	MOVLW	    D'61'
	MOVWF	    TMR0
	BCF	    INTCON,T0IF 	; Se limpia bandera de interrucion por TIMER0
	BSF	    INTCON,T0IE 	; Se habilita interrupción por desbordamiento de TIMER0
	BTFSS	    CONDEUSAR,0		; Si CONDEUSAR es 1 esta listo para iniciar transferencia
	RETURN
	CLRF	    CONDEUSAR
	;MOVWF	    TXREG
	RETURN
	
END