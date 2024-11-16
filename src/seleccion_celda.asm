global array_celdas_seleccionadas
global seleccionar_celda
global seleccionar_proxima_celda

extern printf
extern scanf

section .data

; constantes scanf
mensaje_pedir_movimiento db "Ingrese el movimiento del soldado (posición objetivo): ",0
formato_entrada db "%d", 0

section .bss

array_celdas_seleccionadas resb 9
buffer_movimiento_ingresado resb 1
es_movimiento_valido resb 1 ; (0 = invalido, 1 = valido)

section .text

seleccionar_celda:
    mov rax, 33
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
