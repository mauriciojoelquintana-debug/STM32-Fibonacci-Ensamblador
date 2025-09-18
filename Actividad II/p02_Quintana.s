                THUMB

;--- Área de Datos ---
                AREA    my_data, DATA, READWRITE
                ALIGN
Fib_Result      SPACE   192         ; Espacio en SRAM para guardar los resultados

;--- Área de Código ---
                AREA    my_code, CODE, READONLY
                ENTRY
                EXPORT  main_asm    ; Hacemos la etiqueta "main_asm" visible para otros archivos

main_asm                            ; Esta es la etiqueta de inicio de tu lógica
;--- Módulo de Inicialización de Variables ---
    LDR     R0, =Fib_Result
    LDR     R1, =9

    MOV     R2, #0
    MOV     R3, #1

    STR     R2, [R0], #4
    STR     R3, [R0], #4

    SUBS    R1, R1, #2

;--- Módulo Principal (Bucle de Cálculo) ---
bucle
    ADD     R4, R2, R3
    STR     R4, [R0], #4

    MOV     R2, R3
    MOV     R3, R4

    SUBS    R1, R1, #1
    BNE     bucle

;--- Módulo de Fin ---
fin
    B       fin

    END