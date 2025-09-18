                THUMB               

;Área del Vector de Reset  
                AREA    RESET, DATA, READONLY
                EXPORT  __Vectors

__Vectors
                DCD     0x20005000  
                DCD     Reset_Handler; 

;Área de Datos 
                AREA    my_data, DATA, READWRITE
                ALIGN
Fib_Result      SPACE   192         

;Área de Código Principal 
                AREA    my_code, CODE, READONLY
                ENTRY               
                EXPORT  Reset_Handler

Reset_Handler
;Módulo de Inicialización de Variables 
    LDR     R0, =Fib_Result 
    LDR     R1, =9          

    MOV     R2, #0          
    MOV     R3, #1          

    STR     R2, [R0], #4
    STR     R3, [R0], #4

    SUBS    R1, R1, #2

;Bucle de Cálculo 
bucle
    ADD     R4, R2, R3
    STR     R4, [R0], #4

    MOV     R2, R3
    MOV     R3, R4

    SUBS    R1, R1, #1
    BNE     bucle


fin
    B       fin

    END