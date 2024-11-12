global movimientos_soldado

section .text

; Retorna un arreglo con los índices de offsets de las posibles posiciones a
; moverse. Es decir, si la ficha se tiene como opación moverse a la siguiente
; fila, este arreglo contrendría un +7, si se puede mover a la izquierda sería
; -1, a la derecha +1, etc.
; El arreglo está terminado en 0, es decir, si solo tiene un 0 es porque la
; ficha no se puede mover.
; Parámetros:
;  • rdi - Posición actual del soldado (se asume que es válida ya)
;  • rsi - Puntero al tablero
; Retorna:
;  • rax - Puntero al arreglo de índices
movimientos_soldado:
    push rbp
    mov rbp, rsp
    sub rsp, 4

    ; Calculamos fila y columna
    mov rax, rdi
    mov rcx, 7
    xor rdx, rdx
    div rcx          ; rax = fila, rdx = columna
    mov r8, rax      ; r8 = fila
    mov r9, rdx      ; r9 = columna

    ; Inicializamos el índice para el array de movimientos
    xor rcx, rcx     ; rcx = índice del array
    lea r10, [rbp-4] ; r10 = puntero al array

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
    cmp r11, 48
    jg .finalizar
    cmp BYTE [rsi + r11], ' '
    jne .check_diagonal_izq
    mov BYTE [r10 + rcx], 7
    inc rcx

.check_diagonal_izq:
    ; Verificar diagonal izquierda
    mov r11, rdi
    add r11, 6
    cmp r11, 48
    jg .check_diagonal_der
    cmp BYTE [rsi + r11], ' '
    jne .check_diagonal_der
    mov BYTE [r10 + rcx], 6
    inc rcx

.check_diagonal_der:
    ; Verificar diagonal derecha
    mov r11, rdi
    add r11, 8
    cmp r11, 48
    jg .finalizar
    cmp BYTE [rsi + r11], ' '
    jne .finalizar
    mov BYTE [r10 + rcx], 8
    inc rcx
    jmp .finalizar

.aspa_izquierda:
    ; Si estamos en la última fila
    cmp r8, 5
    je .agregar_mov_derecha

    ; Verificar movimiento vertical/diagonal
    mov r11, rdi
    add r11, 7
    cmp BYTE [rsi + r11], ' '
    jne .check_diagonal_der_aspa_izq
    mov BYTE [r10 + rcx], 7
    inc rcx

    ; Acá estamos seguros de que no estamos en la última fila de la sección
    ; horizontal de la cruz, por lo que, estando en el aspa izquierda, cualquier
    ; movimiento diagonal a la derecha es válido a menos que esté ocupada esa
    ; casilla
.check_diagonal_der_aspa_izq:
    ; Solo diagonal derecha
    mov r11, rdi
    add r11, 8
    cmp BYTE [rsi + r11], ' '
    jne .agregar_mov_derecha
    mov BYTE [r10 + rcx], 8
    inc rcx
    jmp .agregar_mov_derecha

.aspa_derecha:
    ; Si estamos en la última fila
    cmp r8, 5
    je .agregar_mov_izquierda

    ; Verificar movimiento vertical/diagonal
    mov r11, rdi
    add r11, 7
    cmp BYTE [rsi + r11], ' '
    jne .check_diagonal_izq_aspa_der
    mov BYTE [r10 + rcx], 7
    inc rcx

.check_diagonal_izq_aspa_der:
    ; Solo diagonal izquierda
    mov r11, rdi
    add r11, 6
    cmp r11, 48
    jg .agregar_mov_izquierda
    cmp BYTE [rsi + r11], ' '
    jne .agregar_mov_izquierda
    mov BYTE [r10 + rcx], 6
    inc rcx
    jmp .agregar_mov_izquierda

.agregar_mov_derecha:
    mov r11, rdi
    inc r11
    cmp BYTE [rsi + r11], ' '
    jne .finalizar
    mov BYTE [r10 + rcx], 1
    inc rcx
    jmp .finalizar

.agregar_mov_izquierda:
    mov r11, rdi
    dec r11
    cmp BYTE [rsi + r11], ' '
    jne .finalizar
    mov BYTE [r10 + rcx], -1
    inc rcx

.finalizar:
    mov BYTE [r10 + rcx], 0 ; Terminamos el array con un 0
    lea rax, [rbp-4]        ; Retornamos el puntero al array en rax
    leave
    ret
