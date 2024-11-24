    global cargar_movimientos_soldado
    global efectuar_movimiento_soldado

    extern array_movimientos_posibles
    extern tablero

    section .text

    ; actualiza el `array_movimientos_posibles` con los índices de las celdas a las
    ; que se puede mover el soldado dado
    ;
    ; parámetros:
    ; - rdi: índice de la celda actual soldado
    ;
    ; * el parámetro se asume como ya validado
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

    ; primero verificamos si estamos en las aspas
    cmp r9, 1
    jle .aspa_izquierda
    cmp r9, 5
    jge .aspa_derecha

    ; si no estamos en las aspas, verificamos movimientos normales

    .check_verticales:
    ; verificar movimiento vertical
    mov r11, rdi
    add r11, 7

    ; verificar si ya estamos en el fondo de la fortaleza (nos salimos del tablero
    ; si avanzamos a la siguiente fila).
    ;
    cmp r11, 48
    jg .finalizar
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_izq
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    .check_diagonal_izq:
    ; verificar diagonal izquierda
    ; si estamos en la columna 2 y nos movemos a la izquierda, nos estaríamos
    ; saliendo del tablero
    ;
    cmp r9, 2
    jle .check_diagonal_der
    mov r11, rdi
    add r11, 6
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_der
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    .check_diagonal_der:
    ; verificar diagonal derecha
    ; si estamos en la columna 4 y nos movemos a la izquierda, nos estaríamos
    ; saliendo del tablero
    ;
    cmp r9, 4
    jge .finalizar
    mov r11, rdi
    add r11, 8
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx
    jmp .finalizar

    .aspa_izquierda:
    ; si estamos en la última fila
    cmp r8, 4
    je .agregar_mov_derecha

    ; no estamos en la última fila del aspa, por lo que al movernos hacia
    ; adelante no nos saldríamos del tablero
    ;
    mov r11, rdi
    add r11, 7
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_der_aspa_izq
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; acá estamos seguros de que no estamos en la última fila de la sección
    ; horizontal de la cruz, por lo que, estando en el aspa izquierda, cualquier
    ; movimiento diagonal a la derecha es válido a menos que esté ocupada esa
    ; casilla
    ;
    .check_diagonal_der_aspa_izq:
    ; solo diagonal derecha
    mov r11, rdi
    add r11, 8
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx
    jmp .finalizar

    .aspa_derecha:
    ; si estamos en la última fila
    cmp r8, 4
    je .agregar_mov_izquierda

    mov r11, rdi
    add r11, 7
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_izq_aspa_der
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    .check_diagonal_izq_aspa_der:
    ; solo diagonal izquierda
    mov r11, rdi
    add r11, 6
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx
    jmp .finalizar

    .agregar_mov_derecha:
    mov r11, rdi
    inc r11
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx
    jmp .finalizar

    .agregar_mov_izquierda:
    mov r11, rdi
    dec r11
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    .finalizar:
    mov r8, 12 ; tamaño máximo del arreglo
    sub r8, rcx ; calculamos cuántas posiciones nos faltan llenar

    mov r9, rcx ; guardamos la posición inicial en r9
    mov rcx, r8 ; movemos a rcx la cantidad de iteraciones para loop

    .loop_rellenar:
    mov byte [array_movimientos_posibles + r9], 0
    inc r9
    loop .loop_rellenar

    ret

    ; mueve a un soldado de lugar
    ;
    ; parámetro:
    ; - rdi: celda del soldado a mover
    ; - rsi: celda a la que mover el soldado
    ;
    ; * ambos parámetros se asumen como ya validados
    ;
efectuar_movimiento_soldado:
    mov r8b, [tablero + rdi]
    mov byte [tablero + rdi], ' '
    mov byte [tablero + rsi], r8b

    ret
