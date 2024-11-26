    global cargar_movimientos_oficial
    global definir_posiciones_iniciales_oficiales
    global efectuar_movimiento_oficial

    extern array_movimientos_posibles
    extern tablero

    %define CANTIDAD_COLUMNAS 7

    section .bss
    movimientos_oficial1 resb 1 ; Contador de movimientos para el Oficial 1
    movimientos_oficial2 resb 1 ; Contador de movimientos para el Oficial 2
    capturas_oficial1 resb 1  ; Contador de capturas para el Oficial 1
    capturas_oficial2 resb 1  ; Contador de capturas para el Oficial 2

    ptr_pos_oficial_actual resq 1
    ptr_cant_capturas_oficial_actual resq 1
    ptr_cant_movimientos_oficial_actual resq 1

    section .data
    mensaje_estadisticas db "Estadísticas del juego:", 0
    mensaje_oficial_1 db "Estadísticas del Oficial 1:", 0
    mensaje_oficial_2 db "Estadísticas del Oficial 2:", 0
    
    pos_oficial_1 db 39
    pos_oficial_2 db 44
    cant_capturas_oficial_1 db 0
    cant_capturas_oficial_2 db 0
    cant_movimientos_oficial_1 db 0
    cant_movimientos_oficial_2 db 0

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

    ; ========== ARRIBA ==========
    ;
    .check_limites_arriba:
    ; si estamos en una columa entre la 2 y la 4 (inclusive) significa que no
    ; estamos en las aspas, por lo tanto, el único límite que nos importa es el
    ; límite superior de todo el tablero.
    ;
    cmp r9, 2
    jl .check_normal_arriba_aspa_horizontal
    cmp r9, 4
    jg .check_normal_arriba_aspa_horizontal
    jmp .check_captura_arriba

    ; en el caso de estar en las aspas, el límite superior que nos importa es el
    ; de las aspas.
    ;
    .check_normal_arriba_aspa_horizontal:
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

    ; ========== ABAJO ==========
    ;
    .check_limites_abajo:
    ; de nuevo, primero verificamos si estamos en una posicion donde tenemos
    ; condiciones especiales para el movimiento en cuestión (en las aspas
    ; horizontales para el caso de movimientos hacia abajo).
    ;
    cmp r9, 2
    jl .check_normal_abajo_aspa_horizontal
    cmp r9, 4
    jg .check_normal_abajo_aspa_horizontal
    jmp .check_captura_abajo

    ; en el caso de estar en las aspas, el límite inferior que nos importa es el
    ; de las aspas.
    ;
    .check_normal_abajo_aspa_horizontal:
    ; Si estamos en las aspas laterales, no permitimos ningun movimiento hacia
    ; abajo en la última fila.
    ;
    cmp rax, 4
    je .check_limites_izquierda

    ; si estamos en la penúltima fila de las aspas no permitimos
    ; movimientos de captura hacia abajo.
    ;
    cmp rax, 3
    je .check_normal_abajo

    .check_captura_abajo:
    ; verificar si hay un soldado directamente abajo
    mov r11, rdi
    add r11, 7

    cmp byte [tablero + r11], 'X'
    jne .check_normal_abajo

    ; para captura, verificar la siguiente posición
    add r11, 7 ; r11 ahora tiene la posición después del salto sobre el soldado

    ; verificar que no nos salimos del tablero (por abajo)
    cmp r11, 49
    jge .check_limites_izquierda

    ; verificar que la posición de salto está vacía
    cmp byte [tablero + r11], ' '
    jne .check_limites_izquierda

    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; si puedo hacer un movimiento de captura hacia abajo, automáticamente no
    ; puedo hacer un movimiento normal hacia abajo, porque significa que la
    ; celda de abajo está ocupada por un soldado.
    jmp .check_limites_izquierda

    .check_normal_abajo:
    ; verificar si la casilla de abajo está vacía
    mov r11, rdi
    add r11, 7

    cmp byte [tablero + r11], ' '
    jne .check_limites_izquierda
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; ========== IZQUIERDA ==========
    ;
    .check_limites_izquierda:
    ; verificamos si estamos en una fila donde tenemos condiciones especiales
    ; (en las aspas verticales para movimientos laterales)
    ;
    cmp r8, 2 ; r8 tiene la fila actual
    jl .check_normal_izquierda_aspa_vertical
    cmp r8, 4
    jg .check_normal_izquierda_aspa_vertical
    jmp .check_captura_izquierda

    .check_normal_izquierda_aspa_vertical:
    ; Si estamos en las aspas verticales, no permitimos movimiento hacia
    ; la izquierda en la columna más a la izquierda
    ;
    cmp r9, 2
    je .check_limites_derecha

    ; si estamos en la segunda columna desde la izquierda no permitimos
    ; movimientos de captura hacia la izquierda
    ;
    cmp r9, 3
    je .check_normal_izquierda

    .check_captura_izquierda:
    ; verificar si hay un soldado directamente a la izquierda
    mov r11, rdi
    dec r11 ; la casilla de la izquierda a la actual

    cmp byte [tablero + r11], 'X'
    jne .check_normal_izquierda

    ; para captura, verificar la siguiente posición
    dec r11 ; r11 ahora tiene la posición después del salto sobre el soldado

    ; verificar que seguimos en la misma fila después del salto
    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx
    pop rcx

    cmp rax, r8 ; comparamos la fila nueva con la fila actual
    jne .check_normal_izquierda ; si no es la misma fila, el movimiento no es válido

    ; verificar que la posición de salto está vacía
    cmp byte [tablero + r11], ' '
    jne .check_limites_derecha

    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx
    jmp .check_limites_derecha

    .check_normal_izquierda:
    ; verificar si la casilla a la izquierda está vacía
    mov r11, rdi
    dec r11

    ; verificar que seguimos en la misma fila
    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx
    pop rcx

    cmp rax, r8 ; comparamos la fila nueva con la fila actual
    jne .check_limites_derecha ; si no es la misma fila, el movimiento no es válido

    cmp byte [tablero + r11], ' '
    jne .check_limites_derecha
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; ========== DERECHA ==========
    ;
    .check_limites_derecha:
    ; verificamos si estamos en una fila donde tenemos condiciones especiales
    ; (en las aspas verticales para movimientos laterales)
    ;
    cmp r8, 2 ; r8 tiene la fila actual
    jl .check_normal_derecha_aspa_vertical
    cmp r8, 4
    jg .check_normal_derecha_aspa_vertical
    jmp .check_captura_derecha

    .check_normal_derecha_aspa_vertical:
    ; Si estamos en las aspas verticales, no permitimos movimiento hacia
    ; la derecha en la columna más a la derecha
    ;
    cmp r9, 4
    je .check_limites_diagonal_arriba_izquierda

    ; si estamos en la penúltima columna desde la derecha no permitimos
    ; movimientos de captura hacia la derecha
    ;
    cmp r9, 3
    je .check_normal_derecha

    .check_captura_derecha:
    ; verificar si hay un soldado directamente a la derecha
    mov r11, rdi
    inc r11 ; la casilla de la derecha a la actual

    cmp byte [tablero + r11], 'X'
    jne .check_normal_derecha

    ; para captura, verificar la siguiente posición
    inc r11 ; r11 ahora tiene la posición después del salto sobre el soldado

    ; verificar que seguimos en la misma fila después del salto
    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx
    pop rcx

    cmp rax, r8 ; comparamos la fila nueva con la fila actual
    jne .check_normal_derecha ; si no es la misma fila, el movimiento no es válido

    ; verificar que la posición de salto está vacía
    cmp byte [tablero + r11], ' '
    jne .check_limites_diagonal_arriba_izquierda

    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx
    jmp .check_limites_diagonal_arriba_izquierda

    .check_normal_derecha:
    ; verificar si la casilla a la derecha está vacía
    mov r11, rdi
    inc r11

    ; verificar que seguimos en la misma fila
    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rax = nueva fila
    pop rcx

    cmp rax, r8 ; comparamos la fila nueva con la fila actual
    jne .check_limites_diagonal_arriba_izquierda ; si no es la misma fila, el movimiento no es válido

    cmp byte [tablero + r11], ' '
    jne .check_limites_diagonal_arriba_izquierda
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; ========== DIAGONAL ARRIBA IZQUIERDA ==========
    ;
    .check_limites_diagonal_arriba_izquierda:
    mov r11, rdi
    sub r11, 8

    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rax = nueva fila; rdx = nueva columna
    pop rcx

    ; Si nos salimos del tablero por arriba el movimiento es invalido.
    cmp rax, 0
    jl .check_limites_diagonal_arriba_derecha

    ; Si nos salimos del tablero por la izquierda el movimiento es invalido
    ; (esto lo checkeamos como antes, comparando con la columna actual, si es
    ; mayor, tenemos wrap-around)
    ;
    cmp rdx, r9 ; comparamos la nueva columna con la anterior
    jge .check_limites_diagonal_arriba_derecha

    ; Si caemos en el cuadrado 2x2 de la esquina superior o inferieor izquierda es un
    ; movimiento invalido. (este sería el checkeo de las aspas tanto verticales
    ; como horizontales).
    ;
    ; matriz 2x2 esquina superior izquierda
    cmp rax, 2 ; fila
    jge .check_mov_arriba_matriz_inferior_izquierda
    cmp rdx, 2 ; col
    jge .check_mov_arriba_matriz_inferior_izquierda
    jmp .check_limites_diagonal_arriba_derecha ; acá fila <= 1 && col <= 1

    ; matriz 2x2 esquina inferior izquierda
    .check_mov_arriba_matriz_inferior_izquierda:
    cmp rax, 5 ; fila
    jl .check_normal_arriba_izquierda
    cmp rdx, 2 ; col
    jge .check_normal_arriba_izquierda
    jmp .check_limites_diagonal_arriba_derecha ; acá fila >= 5 && col <= 1

    .check_normal_arriba_izquierda:
    cmp byte [tablero + r11], ' '
    jne .check_limites_diagonal_arriba_derecha
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; ========== DIAGONAL ARRIBA DERECHA ==========
    ;
    .check_limites_diagonal_arriba_derecha:
    mov r11, rdi
    sub r11, 6

    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rax = nueva fila; rdx = nueva columna
    pop rcx

    ; Si nos salimos del tablero por arriba el movimiento es invalido.
    cmp rax, 0
    jl .check_limites_diagonal_abajo_derecha

    ; Si nos salimos del tablero por la derecha el movimiento es invalido
    cmp rdx, r9 ; comparamos la nueva columna con la anterior
    jle .check_limites_diagonal_abajo_derecha

    ; Checkeo de las matrices 2x2 en las esquinas
    ; matriz 2x2 esquina superior derecha
    cmp rax, 2 ; fila
    jge .check_mov_arriba_matriz_inferior_derecha
    cmp rdx, 4 ; col
    jle .check_mov_arriba_matriz_inferior_derecha
    jmp .check_limites_diagonal_abajo_derecha ; acá fila <= 1 && col >= 5

    .check_mov_arriba_matriz_inferior_derecha:
    cmp rax, 5 ; fila
    jl .check_normal_arriba_derecha
    cmp rdx, 4 ; col
    jle .check_normal_arriba_derecha
    jmp .check_limites_diagonal_abajo_derecha ; acá fila >= 5 && col >= 5

    .check_normal_arriba_derecha:
    cmp byte [tablero + r11], ' '
    jne .check_limites_diagonal_abajo_derecha
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; ========== DIAGONAL ABAJO DERECHA ==========
    .check_limites_diagonal_abajo_derecha:
    mov r11, rdi
    add r11, 8

    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rax = nueva fila; rdx = nueva columna
    pop rcx

    ; Si nos salimos del tablero por abajo el movimiento es invalido.
    cmp rax, 6
    jg .check_limites_diagonal_abajo_izquierda

    ; Si nos salimos del tablero por la derecha el movimiento es invalido
    cmp rdx, r9 ; comparamos la nueva columna con la anterior
    jle .check_limites_diagonal_abajo_izquierda

    ; Checkeo de las matrices 2x2 en las esquinas
    ; matriz 2x2 esquina superior derecha
    cmp rax, 2 ; fila
    jge .check_mov_abajo_matriz_inferior_derecha
    cmp rdx, 4 ; col
    jle .check_mov_abajo_matriz_inferior_derecha
    jmp .check_limites_diagonal_abajo_izquierda ; acá fila <= 1 && col >= 5

    .check_mov_abajo_matriz_inferior_derecha:
    cmp rax, 5 ; fila
    jl .check_normal_abajo_derecha
    cmp rdx, 4 ; col
    jle .check_normal_abajo_derecha
    jmp .check_limites_diagonal_abajo_izquierda ; acá fila >= 5 && col >= 5

    .check_normal_abajo_derecha:
    cmp byte [tablero + r11], ' '
    jne .check_limites_diagonal_abajo_izquierda
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; ========== DIAGONAL ABAJO IZQUIERDA ==========
    .check_limites_diagonal_abajo_izquierda:
    mov r11, rdi
    add r11, 6

    push rcx
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rax = nueva fila; rdx = nueva columna
    pop rcx

    ; Si nos salimos del tablero por abajo el movimiento es invalido.
    cmp rax, 6
    jg .finalizar

    ; Si nos salimos del tablero por la izquierda el movimiento es invalido
    cmp rdx, r9 ; comparamos la nueva columna con la anterior
    jge .finalizar

    ; Si caemos en el cuadrado 2x2 de la esquina superior o inferior izquierda es un
    ; movimiento invalido.
    ; matriz 2x2 esquina superior izquierda
    cmp rax, 2 ; fila
    jge .check_mov_abajo_matriz_inferior_izquierda
    cmp rdx, 2 ; col
    jge .check_mov_abajo_matriz_inferior_izquierda
    jmp .finalizar ; acá fila <= 1 && col <= 1

    .check_mov_abajo_matriz_inferior_izquierda:
    cmp rax, 5 ; fila
    jl .check_normal_abajo_izquierda
    cmp rdx, 2 ; col
    jge .check_normal_abajo_izquierda
    jmp .finalizar ; acá fila >= 5 && col <= 1

    .check_normal_abajo_izquierda:
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
    ; primero detectamos que oficial estamos moviendo
    .moviendo_oficial_1:
    cmp dil, byte [pos_oficial_1]
    jne .moviendo_oficial_2

    mov qword [ptr_pos_oficial_actual], pos_oficial_1
    mov qword [ptr_cant_capturas_oficial_actual], cant_capturas_oficial_1
    mov qword [ptr_cant_movimientos_oficial_actual], cant_movimientos_oficial_1

    jmp .incrementar_movimientos_oficial

    .moviendo_oficial_2:
    mov qword [ptr_pos_oficial_actual], pos_oficial_2
    mov qword [ptr_cant_capturas_oficial_actual], cant_capturas_oficial_2
    mov qword [ptr_cant_movimientos_oficial_actual], cant_movimientos_oficial_2

    .incrementar_movimientos_oficial:
    ; una vez ya sabemos a que oficial nos referimos, incrementamos la cantidad
    ; de movimientos (esta función siempre mueve al oficial, aunque sea
    ; retirado del tablero, igual cuenta como movimiento).
    mov rbp, [ptr_cant_movimientos_oficial_actual]
    mov al, byte [rbp]
    inc al
    mov byte [rbp], al

    ; luego hacemos el movimiento (sabemos que es válido)
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
    ; bl = índice absoluto del movimiento posible
    mov bl, byte [array_movimientos_posibles + rcx]
    cmp bl, 0
    je .finalizar ; no había movimientos de captura disponibles

    ; si tenía un movimiento que me movía 14 celdas (2 filas hacia arriba o 2
    ; hacia abajo) o 2 celdas (2 izquierda o 2 derecha), entonces significa que
    ; tenía un movimiento de captura.
    ;
    sub bl, dil ; dil = índice absoluto de la posición actual (para encontrar el offset)
    ; este calculo me calcula el offset (con signo)
    test bl, bl
    jge .distancia_absoluta_celdas
    neg bl

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
    ; en este caso eliminamos al oficial del tablero (ya lo habíamos movido)
    mov byte [tablero + rsi], ' '
    mov rax, 1
    jmp .finalizar

    .efectuar_captura:
    mov rbx, rsi
    sub rbx, rdi ; celda anterior
    sar rbx, 1 ; dividimos entre 2 para encontrar la celda sobre la que saltamos

    add rdi, rbx ; offset
    mov byte [tablero + rdi], ' '

    ; incrementamos la estadística de captura del oficial
    mov rbp, [ptr_cant_capturas_oficial_actual]
    mov al, byte [rbp]
    inc al
    mov byte [rbp], al

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
