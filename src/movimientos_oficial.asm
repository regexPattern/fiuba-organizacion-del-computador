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

    .check_limites_arriba:
    ; si estamos en una columa entre la 2 y la 4 (inclusive) significa que no
    ; estamos en las aspas, por lo tanto, el único límite que nos importa es el
    ; límite superior de todo el tablero.
    ;
    cmp r9, 2
    jl .check_captura_arriba
    cmp r9, 4
    jle .check_captura_arriba

    ; en el caso de estar en las aspas, el límite superior que nos importa es el
    ; de las aspas.
    ;
    .check_normal_arriba_aspa_lateral:
    ; Si estamos en las aspas laterales, no permitimos ningun movimiento hacia
    ; arriba en la primera fila.
    ;
    cmp rax, 2
    je .check_limites_abajo

    ; a su vez, si estamos en la segunda fila de las aspas no permitimos
    ; movimientos de captura hacia arriba.
    ;
    cmp rax, 3
    je .check_normal_arriba

    .check_captura_arriba:
    ; verificar si hay un soldado directamente arriba
    mov r11, rdi
    sub r11, 7

    cmp byte [tablero + r11], 'X'
    jne .check_normal_arriba

    ; para captura, verificar la siguiente posición
    sub r11, 7 ; r11 ahora tiene la posición después del salto sobre el oficial

    ; verificar que no nos salimos del tablero
    cmp r11, 0
    jl .check_limites_abajo

    ; verificar que la posición de salto esta vacía
    cmp byte [tablero + r11], ' '
    jne .check_limites_abajo

    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; si puedo hacer un movimiento de captura hacia arriba, automáticamente no
    ; puedo hacer un movimiento normal hacia arriba, porque significa que la
    ; celda de arriba está ocupada por un soldado.

    .check_normal_arriba:
    ; verificar si la casilla de arriba está vacía
    mov r11, rdi
    sub r11, 7

    cmp byte [tablero + r11], ' '
    jne .check_limites_abajo
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    .check_limites_abajo:

    .finalizar:
    mov r8, 9
    sub r8, rcx ; calculamos cuántas posiciones nos faltan llenar

    mov r9, rcx ; guardamos la posición inicial en r9
    mov rcx, r8 ; movemos a rcx la cantidad de iteraciones para loop

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
