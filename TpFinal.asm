list    p = 16f887
include <p16f887.inc>
	
__CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _MCLRE_ON
	
W_TEMP	    EQU	    0x20	
STATUS_TEMP EQU	    0x21
FSR_TEMP    EQU	    0x22
CONDICION   EQU	    0x23
CANTLED     EQU	    0x24
CONTADOR    EQU	    0x27
NUM	    EQU	    0x28
CONTAUX	    EQU	    0x29
FLAG	    EQU	    0x30
CENTENAS    EQU	    0x31
DECENAS	    EQU	    0x32
RESULTADO   EQU	    0x33
ESPACIO	    EQU	    0x34
	    
org	0x00
goto	SETEO
	
org	0x4
goto	INTERRUPCION
	
org	0x5
SETEO   
    
;====================================================================
    ;Se setea de puertos
;====================================================================
	BANKSEL	    TRISD
	CLRF	    TRISD		; Se setea puerto C como salida (leds)
	MOVLW	    b'00000001'		
	MOVWF	    TRISA		; Se setea RA0 como entrada
	BSF	    STATUS, RP1
	BSF	    STATUS, RP0		; Banco 11:3
	BSF	    ANSEL,ANS0		; Se setea RA0 como entrada analogical 	
    
;====================================================================
    ; Se configura del ADC
;====================================================================
	BANKSEL	    ADCON1
	BCF	    ADCON1,ADFM		; Resultado justificado a la izquierda
	BCF	    ADCON1,VCFG0	; Se setea Vref+ como Vdd
	BCF	    ADCON1,VCFG1	; Se setea Vref- como fuente interna (masa)
	BANKSEL	    ADCON0
	BCF	    ADCON0,CHS0		; Se selecciona como canal de entrada
	BCF	    ADCON0,CHS1		; para el ADC el pin ANS0 (RA0)
	BCF	    ADCON0,CHS2
	BCF	    ADCON0,CHS3
	BSF	    ADCON0,ADCS0	; Se selecciona Frc como clock del ADC
	BCF	    ADCON0,ADCS1	; Fosc/8
	BSF	    ADCON0,ADON		; Se activa el modulo ADC
 
;====================================================================
    ; Se configura TMR0
;====================================================================
	BANKSEL	    OPTION_REG
	BCF	    OPTION_REG,T0CS	; TOCS = 0  Se utiliza el clock interno
	BCF	    OPTION_REG,T0SE	; TOSE = 0  Se activa por flanco de subida
	BCF	    OPTION_REG,PSA	; PSA = 0   Se activa el prescaler para TMR0
	BSF	    OPTION_REG,PS2	; Se configura el PRESCALER 1:256
	BSF	    OPTION_REG,PS1	; TMR=61 da 50ms, 10 veces, 0,5s
	BSF	    OPTION_REG,PS0	;
	
;====================================================================
    ; Se configura EUSART
;====================================================================
	BANKSEL	    SPBRG
	MOVLW	    D'25'		; Baud rate = 9600bps
	MOVWF	    SPBRG		; a 4MHZ
	MOVLW	    B'00100100'		; Configures TXSTA as 8 bit transmission,
	MOVWF	    TXSTA		; transmit enabled, async mode, high speed baud rate
	BANKSEL	    RCSTA
	MOVLW	    B'10000000'
	MOVWF	    RCSTA		; Se habilita serial port

;====================================================================
    ;IE
;====================================================================
	BANKSEL	    PIE1
	BSF	    PIE1,ADIE		; Se habilita las int por Receptor ADC
	BCF	    PIE1,TXIE		; Se deshabilita las int por EUSART 
	BSF	    INTCON,PEIE		; Se habilita las int por Perifericos
	BANKSEL	    PIR1
	BCF	    PIR1,ADIF		; Se limpia flag de int de ADC
    
;====================================================================
    ;Inicializacon variables de control
;====================================================================
	MOVLW	    0x0A
	MOVWF	    ESPACIO
	CLRF	    PORTD
	CLRF	    CONDICION		; Se setea condicion en cero (Aun no hay dato para procesar)
        MOVLW	    D'61'
        MOVWF	    TMR0		; Se carga el valor de TMR0
	BSF	    INTCON,T0IE 	; Se habilita interrupción por desbordamiento de TIMER0
        BCF	    INTCON,T0IF 	; Se limpia bandera de interrucion por TIMER0
        BSF	    INTCON,GIE		; Se habilita las interrupciones Globales
    

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

; Actualiza el valor de PORTD
MOSTRARLED
	MOVF	    CANTLED,W
	CALL	    TABLA
	MOVWF	    PORTD
EUSAR
	CLRF	    CENTENAS		; Se limpia el contador de centanas
	CLRF	    DECENAS		; Se limpia el contador de decenas
AUMCEN
	MOVLW	    D'100'
	CALL	    AUX2		; Se llama rutina auxiliar para saber si aumentar el contador
	MOVWF	    FLAG		; Se guarda el valor de retorno de la rutina en FLAG
	ADDWF	    CENTENAS,F		; Se suma el valor de retorno al contador de centenas
	BTFSC	    FLAG,0		; Si FLAG es 0, se terminó de contar las centenas y se pasa a las decenas
	GOTO	    AUMCEN		; Si FLAG es 1, todavia no se terminaron de contar las centenas y se hace una iteracion mas
AUMDEC
	MOVLW	    D'10'
	CALL	    AUX2		; Llama rutina auxiliar para saber si aumentar el contador
	MOVWF	    FLAG		; Se guarda el valor de retorno de la rutina en FLAG
	ADDWF	    DECENAS		; Se suma el valor de retorno al contador de decenas
	BTFSC	    FLAG,0		; Si FLAG es 0, se terminó de contar las decenas
	GOTO	    AUMDEC		; Si FLAG es 1, todavia no se terminaron de contar las decenas y se hace una iteracion mas
					; Lo que queda en el RESULTADO son las unidades
	MOVLW	    0x30		; Se codifican los valores a transmitir en ASCII
	ADDWF	    CENTENAS,F
	ADDWF	    DECENAS,F
	ADDWF	    RESULTADO,F
	MOVLW	    CENTENAS		
	MOVWF	    FSR			   
	MOVLW	    D'04'
	MOVWF	    CONTAUX		; Se setea un bucle para realizar 4 iteraciones
BUCSEND
	CALL	    SEND		; Se envia el valor cargado en el INDF
	INCF	    FSR			; Como las CENT,DEC,RES y un espacio estan en posiciones de memoria contiguas
					; Se incrementa fsr y se realizan las 4 iteraciones
	DECFSZ	    CONTAUX
	GOTO	    BUCSEND
	GOTO	    PROGRAMA		; Al terminar de enviar los datos se vuelve al programa

; AUX: Se encarga de comparar el resultado del ADC con el valor de referencia y
; se aumenta la cantidad de led si resultado >= referencia.
; Se retorna 0 si no se sumo un led y 1 si se sumo un led
AUX
	SUBWF	    RESULTADO,W
	BTFSS	    STATUS,C
	RETLW	    D'00'
	INCF	    CANTLED,F
	RETLW	    D'01'
	
AUX2
	SUBWF	    RESULTADO,W		; si RESULTADO < W -> C=0 -> se terminó de contar 
	BTFSS	    STATUS,C
	RETLW	    D'00'		; Si se terminó de contar se retorna un 1 en W
	MOVWF	    RESULTADO		; Si no se terminó de contar se actualiza el valor de resultado
	RETLW	    D'01'		; y se retorna un 1

SEND
	MOVF	    INDF,W
	MOVWF	    TXREG
	BSF	    STATUS, RP0		;banco 1
	BTFSS	    TXSTA, TRMT		;chequea si TRMT está vacío
	GOTO	    $-1
	BCF	    STATUS, RP0		;bank 0, si TRMT está en 1
	RETURN

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
	MOVLW	    0x01
;	CALL	    ISEUSART		; Si ADIF está en 1 fue ADC y llamo a ISADC
	
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
	MOVLW	    D'4'
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
	MOVWF	    RESULTADO		; Se mueve el valor obtenido a resultado
	MOVLW	    D'01'
	MOVWF	    CONDICION		; Se setea  condicion en 1 (Nuevo valor a procesar)
	MOVLW	    D'61'
	MOVWF	    TMR0
	BCF	    INTCON,T0IF 	; Se limpia bandera de interrucion por TIMER0
	BSF	    INTCON,T0IE 	; Se habilita interrupción por desbordamiento de TIMER0
	RETURN	
END
