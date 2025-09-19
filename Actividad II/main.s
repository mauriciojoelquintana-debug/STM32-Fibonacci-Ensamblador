                THUMB
                IMPORT  SystemInit

;�rea de Datos 
                AREA    my_data, DATA, READWRITE
                ALIGN
N_Value         DCD     20
Fib_Result      SPACE   192

;�rea de C�digo Principal 
                AREA    my_code, CODE, READONLY
                ENTRY
                EXPORT  main_asm    

main_asm                        
;Inicializaci�n del reloj del sistema 
    BL      SystemInit

;M�dulo de Inicializaci�n de Variables 
    LDR     R0, =Fib_Result
    LDR     R5, =N_Value
    LDR     R1, [R5]
    MOV     R2, #0
    MOV     R3, #1
    STR     R2, [R0], #4
    STR     R3, [R0], #4
    SUBS    R1, R1, #2

;Bucle de C�lculo 
bucle
    ADD     R4, R2, R3
    STR     R4, [R0], #4
    MOV     R2, R3
    MOV     R3, R4
    SUBS    R1, R1, #1
    BNE     bucle

;M�dulo de Sobrescritura 
    LDR     R5, =Fib_Result
    LDR     R6, =0x20202020
    STR     R6, [R5, #48]

fin
    B       fin

    END                    