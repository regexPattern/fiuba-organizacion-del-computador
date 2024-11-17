global array_movimientos_posibles
global seleccionar_celda
global seleccionar_proxima_celda

extern printf
extern scanf

section .data

; constantes scanf
mensaje_sel_fila db 10," - Ingresa la fila [1-9]: ",0
mensaje_sel_col db " - Ingrese la columna [A-G]: ",0
input_fila db "%i",0
input_col db " %c",0

mensaje_sel_prox_fila db " - Ingresa la fila a la que moverse [1-9]: ",0
mensaje_sel_prox_col db " - Ingrese la columna a la que moverse [A-G]: ",0

section .bss

array_movimientos_posibles resb 9
buffer_movimiento_ingresado resb 1
es_movimiento_valido resb 1 ; (0 = invalido, 1 = valido)

buffer_fila_ingresada resb 1
buffer_col_ingresada resb 1

section .text

; RETORNA:
; * rax - índice de la casilla a mover
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

    movzx r8, byte [buffer_fila_ingresada]
    dec r8

    ; convertir la columna en un número
    movzx r9, byte [buffer_col_ingresada]
    sub r9, "A"

    ; calcular el índice absoluto de la celda seleccionada
    imul r8, 7
    add r8, r9

    mov rax, r8
    ret

seleccionar_proxima_celda:
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

    ret
