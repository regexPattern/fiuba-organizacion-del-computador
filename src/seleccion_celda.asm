    global array_movimientos_posibles
    global seleccionar_celda
    global seleccionar_proxima_celda

    extern printf
    extern scanf

    %define CANTIDAD_COLUMNAS 7

    section .data

    ; constantes scanf
    msg_sel_fila db 10," - Ingresa la fila [1-9]: ",0
    msg_sel_col db 10," - Ingrese la columna [A-G]: ",0

    msg_celdas_disponibles db 10,0x1b,"[48;5;33m   ",0x1b,"[0m"," Celdas marcadas como disponibles",10,0
    msg_sel_prox_fila db 10," - Ingresa la fila a la que moverse [1-9]: ",0
    msg_sel_prox_col db 10," - Ingrese la columna a la que moverse [A-G]: ",0

    msg_error_filas db 10,0x1b,"[38;5;231;48;5;31m Fila ingresada es inválida ",0x1b,"[0m",10,0
    msg_error_columnas db 10,0x1b,"[38;5;231;48;5;31m Columna ingresada es inválida ",0x1b,"[0m",10,0

    input_fila db " %c",0
    input_col db " %c",0

    section .bss

    array_movimientos_posibles resb 12
    buffer_movimiento_ingresado resb 1
    es_movimiento_valido resb 1 ; (0 = invalido, 1 = valido)

    buffer_fila_ingresada resb 1
    buffer_col_ingresada resb 1
    buffer_stdin_ptr resq 1

    section .text

    ; retorna:
    ; - rax: índice de la casilla a mover
    ;
seleccionar_celda:
    mov rdi, msg_sel_fila
    call printf

    mov rdi, input_fila
    mov rsi, buffer_fila_ingresada
    call scanf

    mov al, byte [buffer_fila_ingresada] 

    cmp al, "1"
    jl .fila_invalida
    cmp al, "7"
    jg .fila_invalida
    jmp .fila_valida

    .fila_invalida:
    mov rdi, msg_error_filas
    call printf
    jmp seleccionar_celda

    .fila_valida:
    mov rdi, msg_sel_col
    call printf

    mov rdi, input_col
    mov rsi, buffer_col_ingresada
    call scanf

    mov al, byte [buffer_col_ingresada]
    
    ; convertimos a minuscula
    cmp al, "G" ; si nos pasamos por arriba, quiza sea porque ingreso minuscula
    jle .verificar_columna
    sub al, 32 ; diferencia entre "A" y "a" (si es minuscula convertimos a mayuscula)
    mov byte [buffer_col_ingresada], al

    .verificar_columna:
    cmp al, "A"
    jl .columna_invalida
    cmp al, "G"
    jg .columna_invalida
    jmp .columna_valida

    .columna_invalida:
    mov rdi, msg_error_columnas
    call printf

    jmp .fila_valida

    .columna_valida:
    sub rsp, 8
    call convertir_input_a_indice
    add rsp, 8

    ret

    ; retorna:
    ; - rax: índice de la casilla a la que se va a mover la ficha
    ;
seleccionar_proxima_celda:
    mov rdi, msg_celdas_disponibles
    call printf

    .iniciar_seleccion:
    mov rdi, msg_sel_prox_fila
    call printf

    mov rdi, input_fila
    mov rsi, buffer_fila_ingresada
    call scanf

    .testing:
    mov al, byte [buffer_fila_ingresada] 

    cmp al, "1"
    jl .fila_invalida
    cmp al, "7"
    jg .fila_invalida
    jmp .fila_valida

    .fila_invalida:
    mov rdi, msg_error_filas
    call printf
    jmp .iniciar_seleccion

    .fila_valida:
    mov rdi, msg_sel_prox_col
    call printf

    mov rdi, input_col
    mov rsi, buffer_col_ingresada
    call scanf

    mov al, byte [buffer_col_ingresada]
    
    ; convertimos a minuscula
    cmp al, "G"
    jle .verificar_columna
    sub al, 32
    mov byte [buffer_col_ingresada], al

    .verificar_columna:
    cmp al, "A"
    jl .columna_invalida
    cmp al, "G"
    jg .columna_invalida
    jmp .columna_valida

    .columna_invalida:
    mov rdi, msg_error_columnas
    call printf

    jmp .fila_valida

    .columna_valida:
    sub rsp, 8
    call convertir_input_a_indice
    add rsp, 8

    ret

    ; retorna:
    ; - rax: índice de la casilla ingresada
    ;
convertir_input_a_indice:
    movzx rax, byte [buffer_fila_ingresada]
    dec rax ; la filas inician en indice 1 en el tablero

    sub rax, "0" ; convertimos a numero

    ; convertir la columna en un número
    movzx r8, byte [buffer_col_ingresada]
    sub r8, "A"

    ; calcular el índice absoluto de la celda seleccionada
    imul rax, CANTIDAD_COLUMNAS
    add rax, r8

    ret
