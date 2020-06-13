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
NUM	    EQU	    0x28
CONTAUX	    EQU	    0x29
FLAG	    EQU	    0x30
	    
org	0x00
goto	SETEO
	
org	0x4
goto	INTERRUPCION
	
org	0x5
SETEO   
    
;====================================================================
    ;Seteo de puertos
;====================================================================
	BANKSEL	    TRISD
	CLRF	    TRISD		;Seteo puerto C como salida (leds)
	MOVLW	    b'00000001'		
	MOVWF	    TRISA		;Seteo RA0 como entrada
	BSF	    STATUS, RP1
	BSF	    STATUS, RP0		; Banco 11:3
	BSF	    ANSEL,ANS0		; Seteo RA0 como entrada analogical 	
    
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
	BSF	    PIE1,ADIE		; Habilito las int por Receptor ADC
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
	CLRF	    CONDICION		; Se limpia la condicion (No hay datos nuevos)
	CLRF	    CANTLED		; Se establece la cantidad de led encenido en cero
	CLRF	    NUM			; Se limpia el numero de referencia
	MOVLW	    D'08'
	MOVWF	    CONTAUX		; Se carga el bucle con 8
SUMAR
	MOVLW	    D'28'		; Se suma 28 al numero de referencia
	ADDWF	    NUM,F		; Esto se debe a que se tiene 9 valores posibles (256/9)
	MOVF	    NUM,W
	CALL	    AUX			; Se carga W con valor de num y se llama a la subrutina AUX
	MOVWF	    FLAG
	BTFSS	    FLAG,0		; Se verifica si se debe seguir intentado sumar leds
	GOTO	    MOSTRARLED		; Si no es necesario se prenden los leds correspondientes
	DECFSZ	    CONTAUX		; Caso contrario, se decrementa CONTAUX y si no da cero se vuelve a iterar
	GOTO	    SUMAR

; Actualiza el valor de PORTD y vuelve al programa principal
MOSTRARLED
	MOVF	    CANTLED,W
	CALL	    TABLA
	MOVWF	    PORTD
	GOTO	    PROGRAMA

; AUX: Se encarga de comparar el resultado del ADC con el valor de referencia y
; se aumenta la cantidad de led si resultado >= referencia.
; Se retorna 0 si no se sumo un led y 1 si se sumo un led
AUX
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	RETLW	    D'00'
	INCF	    CANTLED,F
	RETLW	    D'01'

; Codifica la cantidad de leds que se debe mostrar, en el valor que se le debe dar a PORTD
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
	BTFSC	    PIR1,ADIF		; Interrumpió ADC?
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
	MOVLW	    D'3'
	SUBWF	    CONTADOR,W
	BTFSS	    STATUS,Z		; ¿Se realizo 10 timer0?
	RETURN				; Si aun no se realizo 10 iteracionde seguidasd de timer0 se retorna
	CLRF	    CONTADOR		; Si no se reinicia el contador,
	BSF	    ADCON0,GO		; se inicia la convercion y
	BCF	    INTCON,T0IE 	; se deshabilita interrupción por desbordamiento de TIMER0
	RETURN
	
ISADC
	BCF	    PIR1, ADIF		; Se limpia el flag de int de ADC
	MOVF	    ADRESH,W
	MOVWF	    RESULTADO		; Movemos el valor obtenido a resultado
	MOVLW	    D'01'
	MOVWF	    CONDICION		; Se setea  condicion en 1 (Nuevo valor a procesar)
	MOVLW	    D'61'
	MOVWF	    TMR0
	BCF	    INTCON,T0IF 	; Se limpia bandera de interrucion por TIMER0
	BSF	    INTCON,T0IE 	; Se habilita interrupción por desbordamiento de TIMER0
	;BTFSS	    CONDEUSAR,0		; Si CONDEUSAR es 1 esta listo para iniciar transferencia
	RETURN
	;CLRF	    CONDEUSAR
	;MOVWF	    TXREG
	;RETURN
	
END