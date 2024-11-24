    global cargar_movimientos_oficial
    global efectuar_movimiento_oficial

    extern array_movimientos_posibles
    extern tablero

    %define CANTIDAD_COLUMNAS 7

    section .text

    ; actualiza el `array_movimientos_posibles` con los índices de las celdas a las
    ; que se puede mover el oficial dado
    ;
    ; parámetros:
    ; - rdi: índice celda actual oficial
    ;
cargar_movimientos_oficial:
    ; Calculamos fila y columna
    mov rax, rdi
    mov rcx, 7
    xor rdx, rdx

    div rcx ; rax = fila, rdx = columna
    mov r8, rax ; r8 = fila
    mov r9, rdx ; r9 = columna

    xor rcx, rcx ; rcx = índice del array

    ; -------------------------------------------
    ; Movimientos hacia arriba
    .check_limites_arriba:
        ; Si estamos en una columna entre la 2 y la 4 (inclusive), el único límite
        ; que nos importa es el límite superior del tablero.
        cmp r9, 2
        jl .check_captura_arriba
        cmp r9, 4
        jle .check_captura_arriba

        ; Si estamos en las aspas laterales, no permitimos movimientos hacia arriba
        cmp rax, 2
        je .check_limites_abajo
        cmp rax, 3
        je .check_normal_arriba

        .check_captura_arriba:
        ; Verificar si hay un soldado directamente arriba
        mov r11, rdi
        sub r11, 7

        cmp byte [tablero + r11], 'X'
        jne .check_normal_arriba

        ; Para captura, verificar la posición después del salto
        sub r11, 7
        cmp r11, 0
        jl .check_limites_abajo
        cmp byte [tablero + r11], ' '
        jne .check_limites_abajo

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_arriba:
        ; Verificar si la casilla de arriba está vacía
        mov r11, rdi
        sub r11, 7

        cmp byte [tablero + r11], ' '
        jne .check_limites_abajo
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

    ; -------------------------------------------
    ; Movimientos hacia abajo
    .check_limites_abajo:
        mov r11, rdi
        add r11, 7

        cmp r11, 49 ; Límite inferior
        jge .check_limites_izquierda

        cmp byte [tablero + r11], 'X'
        jne .check_normal_abajo

        add r11, 7
        cmp r11, 49
        jge .check_limites_izquierda
        cmp byte [tablero + r11], ' '
        jne .check_limites_izquierda

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_abajo:
        mov r11, rdi
        add r11, 7
        cmp byte [tablero + r11], ' '
        jne .check_limites_izquierda
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

    ; -------------------------------------------
    ; Movimientos hacia la izquierda
    .check_limites_izquierda:
        mov r11, rdi
        dec r11

        cmp r9, 0 ; Columna 0 es el límite izquierdo
        jl .check_limites_derecha

        cmp byte [tablero + r11], 'X'
        jne .check_normal_izquierda

        dec r11
        cmp r9, 1
        jl .check_limites_derecha
        cmp byte [tablero + r11], ' '
        jne .check_limites_derecha

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_izquierda:
        mov r11, rdi
        dec r11
        cmp byte [tablero + r11], ' '
        jne .check_limites_derecha
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

    ; -------------------------------------------
    ; Movimientos hacia la derecha
    .check_limites_derecha:
        mov r11, rdi
        inc r11

        cmp r9, 6 ; Columna 6 es el límite derecho
        jg .check_diagonales_superiores

        cmp byte [tablero + r11], 'X'
        jne .check_normal_derecha

        inc r11
        cmp r9, 5
        jg .check_diagonales_superiores
        cmp byte [tablero + r11], ' '
        jne .check_diagonales_superiores

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_derecha:
        mov r11, rdi
        inc r11
        cmp byte [tablero + r11], ' '
        jne .check_diagonales_superiores
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

    ; -------------------------------------------
    ; Movimientos diagonales superiores
    .check_diagonales_superiores:
        ; Arriba izquierda
        mov r11, rdi
        sub r11, 8

        cmp r11, 0
        jl .check_diagonal_superior_derecha
        cmp r9, 0
        je .check_diagonal_superior_derecha

        cmp byte [tablero + r11], 'X'
        jne .check_normal_arriba_izquierda

        sub r11, 8
        cmp r11, 0
        jl .check_diagonal_superior_derecha
        cmp byte [tablero + r11], ' '
        jne .check_diagonal_superior_derecha

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_arriba_izquierda:
        mov r11, rdi
        sub r11, 8
        cmp byte [tablero + r11], ' '
        jne .check_diagonal_superior_derecha
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        ; Arriba derecha
        .check_diagonal_superior_derecha:
        mov r11, rdi
        sub r11, 6

        cmp r11, 0
        jl .check_diagonales_inferiores
        cmp r9, 6
        je .check_diagonales_inferiores

        cmp byte [tablero + r11], 'X'
        jne .check_normal_arriba_derecha

        sub r11, 6
        cmp r11, 0
        jl .check_diagonales_inferiores
        cmp byte [tablero + r11], ' '
        jne .check_diagonales_inferiores

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_arriba_derecha:
        mov r11, rdi
        sub r11, 6
        cmp byte [tablero + r11], ' '
        jne .check_diagonales_inferiores
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

    ; -------------------------------------------
    ; Movimientos diagonales inferiores
    .check_diagonales_inferiores:
        ; Abajo izquierda
        mov r11, rdi
        add r11, 6

        cmp r11, 49
        jge .check_diagonal_inferior_derecha
        cmp r9, 0
        je .check_diagonal_inferior_derecha

        cmp byte [tablero + r11], 'X'
        jne .check_normal_abajo_izquierda

        add r11, 6
        cmp r11, 49
        jge .check_diagonal_inferior_derecha
        cmp byte [tablero + r11], ' '
        jne .check_diagonal_inferior_derecha

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_abajo_izquierda:
        mov r11, rdi
        add r11, 6
        cmp byte [tablero + r11], ' '
        jne .check_diagonal_inferior_derecha
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        ; Abajo derecha
        .check_diagonal_inferior_derecha:
        mov r11, rdi
        add r11, 8

        cmp r11, 49
        jge .finalizar
        cmp r9, 6
        je .finalizar

        cmp byte [tablero + r11], 'X'
        jne .check_normal_abajo_derecha

        add r11, 8
        cmp r11, 49
        jge .finalizar
        cmp byte [tablero + r11], ' '
        jne .finalizar

        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

        .check_normal_abajo_derecha:
        mov r11, rdi
        add r11, 8
        cmp byte [tablero + r11], ' '
        jne .finalizar
        mov byte [array_movimientos_posibles + rcx], r11b
        inc rcx

    ; -------------------------------------------
    .finalizar:
    mov r8, 9
    sub r8, rcx

    mov r9, rcx
    mov rcx, r8

    .loop_rellenar:
    mov byte [array_movimientos_posibles + r9], 0
    inc r9
    loop .loop_rellenar


    ret

    ; mueve a un oficial de lugar y captura al soldado que esté en el camino
    ;
    ; parámetros:
    ; - rdi: índice de la celda del oficial a mover
    ; - rsi: índice de la celda a la que mover el oficial
    ;
    ; retorna:
    ; - rax: 1 si se eliminó al oficial por saltarse su deber de captura, 0 en
    ;   otro caso.
    ;
    ; * ambos parámetros se asumen como ya validados
    ;
efectuar_movimiento_oficial:
    ; primero hacemos el movimiento (sabemos que es válido)
    mov r8b, [tablero + rdi]
    mov byte [tablero + rdi], ' '
    mov byte [tablero + rsi], r8b

    ; verificamos si hicimos un movimiento normal. en este caso las diferencias
    ; entre la fila nueva y la anterior son menor o igual a 1, y las de la
    ; columna tambien:
    ;
    ; (| fila_anterior - fila_actual | <= 1) AND (| columna_anterior - columna_actual | <= 1)

    ; para volver a usarlos luego
    push rdi
    push rsi

    mov rax, rdi
    mov rcx, CANTIDAD_COLUMNAS
    xor rdx, rdx

    div rcx ; rax = fila_anterior, rdx = columna_anterior

    mov r8, rax ; fila_anterior
    mov r9, rdx ; columna_anterior

    mov rax, rsi
    mov rcx, CANTIDAD_COLUMNAS
    xor rdx, rdx

    div rcx ; rax = fila_nueva, rdx = columna_nueva

    mov r10, rax ; fila_nueva
    mov r11, rdx ; columna_nueva

    mov rdi, r8
    mov rsi, r9
    mov rdx, r10
    mov rcx, r11

    call calcular_distancia_entre_celdas

    mov r8, rax ; distancia filas (valor absoluto)
    mov r9, rbx ; distancia columnas (valor absoluto)

    pop rsi ; recupero el índice de la celda anterior
    pop rdi ; y el de la celda a la que me moví

    cmp r8, 1
    jg .efectuar_captura

    cmp r9, 1
    jg .efectuar_captura

    ; si llego acá es porque hicimos un movimiento normal. hay que comprobar que
    ; no teníamos opciones para hacer un movimiento de captura.

    mov rax, 0 ; para retornarlo luego
    mov rcx, 0

    .loop_validacion_sin_captura_disp:
    mov bl, byte [array_movimientos_posibles + rcx]
    cmp bl, 0
    je .finalizar ; no había movimientos de captura disponibles

    ; si tenía un movimiento que me movía 14 celdas (2 filas hacia arriba o 2
    ; hacia abajo) o 2 celdas (2 izquierda o 2 derecha), entonces significa que
    ; tenía un movimiento de captura.
    ;
    sub bl, dl
    test bl, bl
    jge .distancia_absoluta_celdas
    neg al

    .distancia_absoluta_celdas:
    cmp bl, 14
    je .habia_mov_captura_disp
    cmp bl, 2
    je .habia_mov_captura_disp

    inc rcx
    jmp .loop_validacion_sin_captura_disp

    ; no había movimientos de captura disponibles
    jmp .finalizar

    .habia_mov_captura_disp:
    ; en este caso eliminamos al oficial del tablero
    mov byte [tablero + rdi], ' '
    mov rax, 1
    jmp .finalizar

    .efectuar_captura:
    mov rbx, rsi
    sub rbx, rdi ; celda anterior
    sar rbx, 1 ; dividimos entre 2 para encontrar la celda sobre la que saltamos

    add rdi, rbx ; offset
    mov byte [tablero + rdi], ' '

    .finalizar:

    ret

    ; parámetros:
    ; - rdi: número de fila anterior
    ; - rsi: número de columna anterior
    ; - rdx: número de fila nueva
    ; - rcx: número de columna nueva
    ;
    ; retorna:
    ; - rax: la distancia entre la fila anterior y la nueva
    ; - rbx: la distancia entre la columna anterior y la nueva
    ;
    ; * ambas distancias son valores absolutos
    ;
calcular_distancia_entre_celdas:
    ; distancia entre filas
    mov rax, rdx
    sub rax, rdi
    test rax, rax
    jge .columna_absoluta
    neg rax

    ; distancia entre columnas
    .columna_absoluta:
    mov rbx, rcx
    sub rbx, rsi
    test rbx, rbx
    jge .finalizar
    neg rbx

    .finalizar:
    ret