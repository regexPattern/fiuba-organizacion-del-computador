global array_movimientos_soldado
global cargar_movimientos_soldado

%define MAX_MOVIMIENTOS_POSIBLES 4

extern tablero

section .bss

array_movimientos_soldado resb MAX_MOVIMIENTOS_POSIBLES

section .text

; PARÁMETROS:
; * rdi - índice celda actual soldado
;
; RETORNA:
; * rax - puntero al arreglo de movimientos posibles
;
cargar_movimientos_soldado:
    ; calculamos fila y columna
    mov rax, rdi
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rax = fila, rdx = columna

    mov r8, rax ; r8 = fila
    mov r9, rdx ; r9 = columna

    xor rcx, rcx ; rcx = índice del array

    ; Primero verificamos si estamos en las aspas
    cmp r9, 1
    jle .aspa_izquierda
    cmp r9, 5
    jge .aspa_derecha

    ; Si no estamos en las aspas, verificamos movimientos normales

.check_verticales:
    ; Verificar movimiento vertical
    mov r11, rdi
    add r11, 7

    ; Verificar si ya estamos en el fondo del castillo (nos salimos del tablero
    ; si avanzamos a la siguiente fila)
    ;
    cmp r11, 48
    jg .finalizar
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_izq
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx

.check_diagonal_izq:
    ; Verificar diagonal izquierda
    ; Si estamos en la columna 2 y nos movemos a la izquierda, nos estaríamos
    ; saliendo del tablero
    ;
    cmp r9, 2
    jle .check_diagonal_der
    mov r11, rdi
    add r11, 6
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_der
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx

.check_diagonal_der:
    ; Verificar diagonal derecha
    ; Si estamos en la columna 4 y nos movemos a la izquierda, nos estaríamos
    ; saliendo del tablero
    ;
    cmp r9, 4
    jge .finalizar
    mov r11, rdi
    add r11, 8
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx
    jmp .finalizar

.aspa_izquierda:
    ; Si estamos en la última fila
    cmp r8, 4
    je .agregar_mov_derecha

    ; No estamos en la última fila del aspa, por lo que al movernos hacia
    ; adelante no nos saldríamos del tablero
    ;
    mov r11, rdi
    add r11, 7
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_der_aspa_izq
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx

    ; Acá estamos seguros de que no estamos en la última fila de la sección
    ; horizontal de la cruz, por lo que, estando en el aspa izquierda, cualquier
    ; movimiento diagonal a la derecha es válido a menos que esté ocupada esa
    ; casilla
    ;
.check_diagonal_der_aspa_izq:
    ; Solo diagonal derecha
    mov r11, rdi
    add r11, 8
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx
    jmp .finalizar

.aspa_derecha:
    ; Si estamos en la última fila
    cmp r8, 4
    je .agregar_mov_izquierda

    mov r11, rdi
    add r11, 7
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_izq_aspa_der
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx

.check_diagonal_izq_aspa_der:
    ; Solo diagonal izquierda
    mov r11, rdi
    add r11, 6
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx
    jmp .finalizar

.agregar_mov_derecha:
    mov r11, rdi
    inc r11
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx
    jmp .finalizar

.agregar_mov_izquierda:
    mov r11, rdi
    dec r11
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_soldado + rcx], r11b
    inc rcx

.finalizar:
    mov r8, MAX_MOVIMIENTOS_POSIBLES
    sub r8, rcx ; Calculamos cuántas posiciones nos faltan llenar

    mov r9, rcx ; Guardamos la posición inicial en r9
    mov rcx, r8 ; Movemos a rcx la cantidad de iteraciones para loop

.loop_rellenar:
    mov BYTE [array_movimientos_soldado + r9], 0
    inc r9
    loop .loop_rellenar

    ret
