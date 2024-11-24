    global array_movimientos_posibles
    global seleccionar_celda
    global seleccionar_proxima_celda

    extern printf
    extern scanf

    %define CANTIDAD_COLUMNAS 7

    section .data

    ; constantes scanf
    mensaje_sel_fila db 10," - Ingresa la fila [1-9]: ",0
    mensaje_sel_col db " - Ingrese la columna [A-G]: ",0

    mensaje_celdas_disponibles db 10,0x1b,"[48;5;33m   ",0x1b,"[0m"," Celdas marcadas como disponibles",10,0
    mensaje_sel_prox_fila db 10," - Ingresa la fila a la que moverse [1-9]: ",0
    mensaje_sel_prox_col db " - Ingrese la columna a la que moverse [A-G]: ",0

    input_fila db "%i",0
    input_col db " %c",0

    section .bss

    array_movimientos_posibles resb 12
    buffer_movimiento_ingresado resb 1
    es_movimiento_valido resb 1 ; (0 = invalido, 1 = valido)

    buffer_fila_ingresada resb 1
    buffer_col_ingresada resb 1

    section .text

    ; retorna:
    ; - rax: índice de la casilla a mover
    ;
seleccionar_celda:
    mov rdi, mensaje_sel_fila
    call printf

    mov rdi, input_fila
    mov rsi, buffer_fila_ingresada
    call scanf

    mov rdi, mensaje_sel_col
    call printf

    mov rdi, input_col
    mov rsi, buffer_col_ingresada
    call scanf

    sub rsp, 8
    call convertir_input_a_indice
    add rsp, 8

    ret

    ; retorna:
    ; - rax: índice de la casilla a la que se va a mover la ficha
    ;
seleccionar_proxima_celda:
    mov rdi, mensaje_celdas_disponibles
    call printf

    mov rdi, mensaje_sel_prox_fila
    call printf

    mov rdi, input_fila
    mov rsi, buffer_fila_ingresada
    call scanf

    mov rdi, mensaje_sel_prox_col
    call printf

    mov rdi, input_col
    mov rsi, buffer_col_ingresada
    call scanf

    sub rsp, 8
    call convertir_input_a_indice
    add rsp, 8

    ret

    ; retorna:
    ; - rax: índice de la casilla ingresada
    ;
convertir_input_a_indice:
    movzx rax, byte [buffer_fila_ingresada]
    dec rax

    ; convertir la columna en un número
    movzx r8, byte [buffer_col_ingresada]
    sub r8, "A"

    ; calcular el índice absoluto de la celda seleccionada
    imul rax, CANTIDAD_COLUMNAS
    add rax, r8

    ret
