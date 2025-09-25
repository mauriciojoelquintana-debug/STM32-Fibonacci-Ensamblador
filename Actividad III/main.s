;   Este programa controla un LED (PC13) (verde) basado en el estado de dos pines de entrada (PA0, PA1).
;   - Estado "00": LED apagado.
;   - Estado "01": Genera 100 números pseudoaleatorios y enciende el LED.
;   - Estado "10": Ordena los números generados previamente y enciende el LED.

                THUMB
                AREA    RESET, CODE, READONLY
                EXPORT  main

;   DEFINICIÓN DE DIRECCIONES Y CONSTANTES

;Registros del RCC (Reset and Clock Control)
RCC_APB2ENR     EQU     0x40021018  ; Habilitación de reloj para periféricos APB2

;Registros del GPIOA (para las entradas PA0 y PA1)
GPIOA_CRL       EQU     0x40010800  ; Registro de Configuración BAJO (pines 0-7)
GPIOA_IDR       EQU     0x40010808  ; Registro de Datos de Entrada
GPIOA_ODR       EQU     0x4001080C  ; Registro de Datos de Salida (usado para pull-up/down)

;Registros del GPIOC (para el LED en PC13)
GPIOC_CRH       EQU     0x40011004  ; Registro de Configuración ALTO (pines 8-15)
GPIOC_BSRR      EQU     0x40011010  ; Registro Atómico para Set/Reset de bits

;Constantes del programa
SRAM_ADDR       EQU     0x20000100  
NUM_COUNT       EQU     100         

;   SECCIÓN DE DATOS (VARIABLES EN RAM)
                AREA    MY_DATA, DATA, READWRITE
                ALIGN

; Bandera para indicar si los números aleatorios ya fueron generados (0 = no, 1 = sí)
generated_flag  DCD     0

;   CÓDIGO PRINCIPAL
                AREA    MAIN_CODE, CODE, READONLY

main

;   1. HABILITACIÓN DE RELOJES PARA LOS PUERTOS GPIOA y GPIOC

    LDR     R0, =RCC_APB2ENR
    LDR     R1, [R0]
	ORR     R1, R1, #0x14                  ; Habilitar reloj para GPIOA (bit 2) y GPIOC (bit 4)
    STR     R1, [R0]


;   2. CONFIGURACIÓN DE PINES DE ENTRADA (PA0, PA1) como PULL-DOWN
;   Esto asegura que los pines lean '0' si no hay nada conectado.

    LDR     R0, =GPIOA_CRL
    LDR     R1, [R0]
    BIC     R1, R1, #0x000000FF           ; Limpiar la configuración actual de PA0 y PA1
    ORR     R1, R1, #0x00000088           ; Configurar PA0/PA1 como Entrada con Pull-Up/Down
    STR     R1, [R0]

    LDR     R0, =GPIOA_ODR
    LDR     R1, [R0]
    BIC     R1, R1, #0x00000003           ; Poner en 0 los bits 0 y 1 para seleccionar Pull-DOWN
    STR     R1, [R0]

;   3. CONFIGURACIÓN DE PIN DE SALIDA (PC13) PARA EL LED
;   El LED en la placa está en PC13.

    LDR     R0, =GPIOC_CRH
    LDR     R1, [R0]
    BIC     R1, R1, #0x00F00000           ; Limpiar configuración actual de PC13
    ORR     R1, R1, #0x00300000           ; Configurar PC13 como Salida Push-Pull, 50MHz
    STR     R1, [R0]
    
    ; Apagar el LED al inicio (PC13 en ALTO, ya que es activo en bajo)
    LDR     R0, =GPIOC_BSRR
    MOV     R1, #(1 << 13)
    STR     R1, [R0]

;   BUCLE PRINCIPAL (Máquina de estados)

main_loop
    LDR     R0, =GPIOA_IDR
    LDR     R1, [R0]
    AND     R1, R1, #0x03       ; Enmascarar para obtener solo los valores de PA0 y PA1

    CMP     R1, #0x00           ; La entrada es "00"
    BEQ     state_00
    
    CMP     R1, #0x01           ; La entrada es "01"
    BEQ     state_01
    
    CMP     R1, #0x02           ; La entrada es "10"
    BEQ     state_10
    
    B       main_loop


;   ESTADO 00: INICIO / REPOSO
;   Acción: Apaga el LED y espera una nueva entrada.

state_00
    ; Apagar el LED (Poner PC13 en ALTO)
    LDR     R0, =GPIOC_BSRR
    MOV     R1, #(1 << 13)      ; El bit 13 en BSRR SETEA el pin 13.
    STR     R1, [R0]
    
    ; Reiniciar la bandera de generación para permitir una nueva operación
    LDR     R0, =generated_flag
    MOV     R1, #0
    STR     R1, [R0]
    
    B       main_loop           ; Volver al bucle principal a leer entradas

;   ESTADO 01: GENERAR NÚMEROS ALEATORIOS
;   Acción: Si no se han generado, los genera, los guarda en SRAM, activa la bandera y enciende el LED.

state_01
    ; Verificar si los números ya fueron generados para no hacerlo de nuevo
    LDR     R0, =generated_flag
    LDR     R1, [R0]
    CMP     R1, #1
    BEQ     state_01_loop       ; Si la bandera es 1, ya se generaron, solo mantener LED

    ; Si la bandera es 0, generar los números
    BL      generate_randoms    
    
    ; Poner la bandera en 1 para indicar que la operación se completó
    LDR     R0, =generated_flag
    MOV     R1, #1
    STR     R1, [R0]

state_01_loop
    ; Encender el LED (Poner PC13 en BAJO)
    LDR     R0, =GPIOC_BSRR
    MOV     R1, #(1 << (13 + 16)) 
    STR     R1, [R0]
    
    ; Bucle de espera: permanece aquí mientras la entrada sea "01"
check_input_01
    LDR     R0, =GPIOA_IDR
    LDR     R1, [R0]
    AND     R1, R1, #0x03
    CMP     R1, #0x01           
    BEQ     check_input_01      
    
    B       main_loop           

;   ESTADO 10: ORDENAR NÚMEROS
;   Acción: Verifica si los números fueron generados. Si es así, los ordena y enciende el LED. Si no, no hace nada.

state_10
    ; Primero, verificar si los números fueron generados (bandera en 1)
    LDR     R0, =generated_flag
    LDR     R1, [R0]
    CMP     R1, #1
    BNE     main_loop           

    ; Si la bandera es 1, ordenar los números
    BL      sort_numbers        

state_10_loop
    ; Encender el LED (Poner PC13 en BAJO)
    LDR     R0, =GPIOC_BSRR
    MOV     R1, #(1 << (13 + 16))
    STR     R1, [R0]
    
    ; Bucle de espera: permanece aquí mientras la entrada sea "10"
check_input_10
    LDR     R0, =GPIOA_IDR
    LDR     R1, [R0]
    AND     R1, R1, #0x03
    CMP     R1, #0x02           
    BEQ     check_input_10      

    B       main_loop           

;   SUBRUTINAS
; Registros modificados: R0, R1, R2, R3, R4.

generate_randoms
    PUSH    {LR}                
    LDR     R0, =SRAM_ADDR      
    MOV     R1, #NUM_COUNT      
    MOV     R2, #13             
gen_loop
    LDR     R3, =1103515245     
    LDR     R4, =12345        
    MUL     R2, R3, R2          
    ADD     R2, R2, R4          
    STR     R2, [R0], #4        
    SUBS    R1, R1, #1          
    BNE     gen_loop            
    POP     {PC}               

; Registros modificados: R0, R1, R2, R4, R5.

sort_numbers
    PUSH    {LR}                
    LDR     R4, =NUM_COUNT-1   
outer_loop
    CMP     R4, #0
    BEQ     sort_done          

    LDR     R0, =SRAM_ADDR      
    MOV     R5, #0              
inner_loop
    CMP     R5, R4              
    BGE     end_inner_loop     
    
    LDR     R1, [R0]            
    LDR     R2, [R0, #4]!       
    
    CMP     R1, R2              
    BHI     swap                
   
continue_inner
    ADD     R5, R5, #1          
    B       inner_loop

swap
    STR     R2, [R0, #-4]       
    STR     R1, [R0]          
    B       continue_inner

end_inner_loop
    SUBS    R4, R4, #1       
    B       outer_loop

sort_done
    POP     {PC}                

                END