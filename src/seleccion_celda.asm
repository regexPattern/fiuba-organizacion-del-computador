global array_celdas_seleccionadas
global seleccionar_celda
global seleccionar_proxima_celda

extern printf
extern scanf

section .data

; constantes scanf
prompt_sel_fila db " - Ingresa la fila [1-9]: ",0
prompt_sel_col db " - Ingrese la columna [A-G]: ",0
input_fila db "%i",0
input_col db " %c",0

msg_pedir_proxima_celda db " * Ingrese el movimiento del soldado (posición objetivo): ",0
formato_entrada db "%d", 0

section .bss

array_celdas_seleccionadas resb 9
buffer_movimiento_ingresado resb 1
es_movimiento_valido resb 1 ; (0 = invalido, 1 = valido)

buffer_fila_ingresada resb 1
buffer_col_ingresada resb 1

section .text

; DESCRIPCIÓN:
;  Pide la casilla de la ficha a mover.
;
; PARÁMETROS:
; * rdi - puntero al arreglo de movimientos posibles absolutos (no los offsets
;   relativos a la ficha a mover, sino que los índices del 0 al 48).
;
seleccionar_celda:
    mov rdi, prompt_sel_fila
    call printf

    mov rdi, input_fila
    mov rsi, buffer_fila_ingresada
    call scanf

    mov rdi, prompt_sel_col
    call printf

    mov rdi, input_col
    mov rsi, buffer_col_ingresada
    call scanf

    ; TODO: falta validar la fila

    movzx r8, byte [buffer_fila_ingresada]
    dec r8

    ; TODO: falta validar la columna

    ; convertir la columna en un número
    movzx r9, byte [buffer_col_ingresada]
    sub r9, "A"

    ; calcular el índice absoluto de la celda seleccionada
    imul r8, 7
    add r8, r9

    mov rax, r8
    ret

; DESCRIPCIÓN:
;  Pide el movimiento del jugador con la casilla correspondiente a la que se
;  quiere mover.
;
; PARÁMETROS:
; * rdi - puntero al arreglo de movimientos posibles absolutos (no los offsets
;   relativos a la ficha a mover, sino que los índices del 0 al 48).
;
seleccionar_proxima_celda:
    ; mov rdi, mensaje_pedir_movimiento
    ; call printf

    ; mov rdi, formato_entrada
    ; mov rsi, buffer_movimiento_ingresado
    ; call scanf

    ; mov rax, [buffer_movimiento_ingresado]
    ; mov r8, rax ; guardo el movimiento del jugador en r8

    ret
