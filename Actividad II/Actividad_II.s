0x        AREA    RESET, DATA, READONLY
        EXPORT  __isr_vector

__estack    EQU     0x20005000          

__isr_vector
        DCD     __estack               
        DCD     Reset_Handler           

        ALIGN

        AREA    |.text|, CODE, READONLY
        PRESERVE8
        THUMB
        EXPORT  Reset_Handler
        EXPORT  main


; Constantes

SRAM_BASE   EQU     0x20001000          
MAX_N       EQU     47                  


; Reset Handler

Reset_Handler
        LDR     SP, =__estack           
        BL      main

halt_loop
        B       halt_loop

main
        PUSH    {r4, r5, lr}            

        ; Cargar n desde variable
        LDR     r0, =N_value
        LDR     r0, [r0]               

        ; Limitar n a MAX_N
        MOVS    r4, #MAX_N
        CMP     r0, r4
        BLE     n_ok
        MOV     r0, r4                  

n_ok
        ; Puntero de salida
        LDR     r1, =SRAM_BASE

        ; Caso n == 0
        CMP     r0, #0
        BEQ     write_f0_and_done

        ; Escribir F0 = 0
        MOVS    r2, #0                  
        STR     r2, [r1], #4

        ; Escribir F1 = 1
        MOVS    r3, #1                  
        STR     r3, [r1], #4

        ; Si n == 1 -> terminar
        CMP     r0, #1
        BEQ     done

        ; Loop: i = 2 .. n
        MOVS    r5, #2

loop_calc
        ADDS    r4, r2, r3              
        STR     r4, [r1], #4            

        MOV     r2, r3                  
        MOV     r3, r4                  

        ADDS    r5, r5, #1
        CMP     r5, r0
        BLE     loop_calc

        B       done

write_f0_and_done
        MOVS    r2, #0
        STR     r2, [r1], #4
        B       done

done
        POP     {r4, r5, pc}            

        ALIGN

        AREA    |.data|, DATA, READWRITE
        EXPORT  N_value
N_value
        DCD     9                       

        END
