    global cargar_movimientos_soldado
    global efectuar_movimiento_soldado

    extern array_movimientos_posibles
    extern posicion_fortaleza
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
    div rcx ; rax = fila, rdx = columna (actuales)

    mov r8, rax ; r8 = fila
    mov r9, rdx ; r9 = columna
    movzx r10, byte [posicion_fortaleza]

    xor rbp, rbp ; rcx = índice del array

    ; primero miramos si tenemos que considerar los casos especiales para el
    ; movimiento de los soldados, es decir, lo casos de movimiento en direccion
    ; paralela a la fortaleza. si la fortaleza esta en la parte de arriba o
    ; abajo, estas condiciones especiales son movimientos horizontales en las
    ; aspas horizontales, si la fortaleza esta a la derecha o izquierda, son
    ; movimientos verticales a lo largo del aspa vertical
    ;
    cmp r10, "^"
    je .check_aspas_horizontales
    cmp r10, "v"
    je .check_aspas_horizontales

    .check_aspas_verticales:
    cmp r8, 1
    jle .aspa_arriba
    cmp r8, 5
    jge .aspa_abajo
    ; si las aspas son verticales, pero no estoy en las aspas, el movimiento
    ; de avance que tengo permitido es horizontal (hacia izq o der)
    ;
    jmp .check_desplazamiento_hacia_fort

    .check_aspas_horizontales:
    cmp r9, 1
    jle .aspa_izquierda
    cmp r9, 5
    jge .aspa_derecha

    ; si estamos aca no estamos en ninguna de las aspas de ninguna de las
    ; posiciones de la fortaleza

    .check_desplazamiento_hacia_fort:
    ; si la fortaleza esta abajo (v), un desplazamiento vertical significa
    ; pasar a la fila de abajo, si la fortaleza esta arriba (^), significa
    ; retroceder una fila
    ;
    mov r11, rdi ; posicion soldado actual

    cmp r10, ">"
    je .cargar_desplazamiento_derecha
    cmp r10, "v"
    je .cargar_desplazamiento_abajo
    cmp r10, "<"
    je .cargar_desplazamiento_izquierda

    .cargar_desplazamiento_arriba:
    sub r11, 7 ; nueva posicion (retrocedo a la fila de arriba)
    jmp .verificar_desplazamiento_disp

    .cargar_desplazamiento_derecha:
    inc r11 ; nueva posicion (me muevo 1 hacia la derecha)
    jmp .verificar_desplazamiento_disp

    .cargar_desplazamiento_abajo:
    add r11, 7 ; nueva posicion (me muevo 1 fila habia abajo)
    jmp .verificar_desplazamiento_disp

    .cargar_desplazamiento_izquierda:
    dec r11 ; nueva posicion (me muevo 1 hacia la izquierda)

    ; r11 ahora tiene lo posicion a la que me voy a desplazar

    .verificar_desplazamiento_disp:
    ; recordemos que aca estamos verificando los movimientos que no son en las
    ; condiciones limite de cada posicion, es decir, siempre vamos a estar en
    ; el "tronco" en donde este la fortaleza, los unicos limites que nos
    ; afectan son los limites de la matriz 7x7 del tablero, sea por wrap-around
    ; o por irse arriba o abajo de la ultima o primera fila.
    ;
    ; si la fortaleza esta arriba o abajo me interesa verificar los limites de
    ; las filas del tablero, si me salgo por arriba o me salgo por abajo
    ;
    cmp r10, "^"
    jne .check_limite_abajo
    cmp r11, 0 ; comparo con el limite arriba
    jl .finalizar
    jmp .agregar_movimiento_hacia_fort

    .check_limite_abajo:
    cmp r10, "v"
    jne .check_limite_derecha
    cmp r11, 48 ; comparo con el limite abajo
    jg .finalizar
    jmp .agregar_movimiento_hacia_fort

    ; si un desplazamiento hacia la fortaleza es un desplazamiento horizontal,
    ; los limites de los que nos tenemos que preocupar son los wrap-arounds.
    ;
    .check_limite_derecha:
    cmp r10, ">"
    jne .check_limite_izquierda
    mov rax, r11 ; calculo la fila y columna de la proxima posicion para ver el wrap-around
    mov rcx, 7
    xor rdx, rdx
    div rcx ; rdx = nueva columna
    cmp rdx, r9 ; compara columna nueva vs. columna actual
    jl .finalizar ; si columnas nueva < columna actual, no puedo mover hacia la derecha
    jmp .agregar_movimiento_hacia_fort

    .check_limite_izquierda:
    mov rax, r11
    mov rcx, 7
    xor rdx, rdx
    div rcx
    cmp rdx, r9
    jg .finalizar ; si columnas nueva > columna actual, no puedo mover hacia la derecha

    .agregar_movimiento_hacia_fort:
    cmp byte [tablero + r11], ' '
    jne .check_diagonales
    mov byte [array_movimientos_posibles + rbp], r11b ; agregamos el movimiento
    inc rbp

    ; ahora checkeamos las diagonales
    ; el qué significa un movimiento diagonal también cambia con cada posición
    ; de la fortaleza
    .check_diagonales:

    ; =========
    ; ↘ ↘ ↘ ↘ ↘
    ; =========
    .check_diagonal_aba_der: ; (puede ocurrir cuando fortaleza esta en v o >)
    ; solo puedo hacer este movimiento si estoy en el tronco (vertical para v, y horizontal para >)
    cmp r10, "v"
    je .check_diagonal_aba_der_fort_aba
    cmp r10, ">"
    je .check_diagonal_aba_der_fort_der
    jmp .check_diagonal_aba_izq ; si no estoy con fort en v o > no tiene sentido este movimiento

    .check_diagonal_aba_der_fort_aba:
    cmp r9, 4 ; si estamos en la columna 4 y nos movemos en diagonal a la derecha, nos estaríamos saliendo del tronco vertical
    jge .check_diagonal_aba_izq
    jmp .verificar_diagonal_aba_der_disp

    .check_diagonal_aba_der_fort_der:
    cmp r8, 4 ; si etamos en la fila 4 y nos movemos hacia abajo, nos estamos saliendo del tronco horizontal
    jge .check_diagonal_aba_izq

    .verificar_diagonal_aba_der_disp:
    mov r11, rdi
    add r11, 8
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_aba_izq
    mov byte [array_movimientos_posibles + rbp], r11b
    inc rbp

    ; =========
    ; ↙ ↙ ↙ ↙ ↙
    ; =========
    .check_diagonal_aba_izq: ; (puede ocurrir cuando fortaleza esta en v o <)
    cmp r10, "v"
    je .check_diagonal_aba_izq_fort_aba
    cmp r10, "<"
    je .check_diagonal_aba_izq_fort_izq
    jmp .check_diagonal_arr_der

    .check_diagonal_aba_izq_fort_aba:
    cmp r9, 2 ; si estamos en la columna 2 y nos movemos en diagonal a la izq, nos salimos del tronco vertical
    jle .check_diagonal_arr_der
    jmp .verificar_diagonal_aba_izq_disp

    .check_diagonal_aba_izq_fort_izq:
    cmp r8, 4
    jge .check_diagonal_arr_der

    .verificar_diagonal_aba_izq_disp:
    mov r11, rdi
    add r11, 6
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_arr_der
    mov byte [array_movimientos_posibles + rbp], r11b
    inc rbp

    ; =========
    ; ↗ ↗ ↗ ↗ ↗
    ; =========
    .check_diagonal_arr_der:
    ; solo puedo hacer este movimiento si estoy en el tronco (vertical para ^, y horizontal para >)
    cmp r10, "^"
    je .check_diagonal_arr_der_fort_arr
    cmp r10, ">"
    je .check_diagonal_arr_der_fort_der
    jmp .check_diagonal_arr_izq

    .check_diagonal_arr_der_fort_arr:
    cmp r9, 4
    jge .check_diagonal_arr_izq ; me saldria si me muevo a la derecha
    jmp .verificar_diagonal_arr_der_disp

    .check_diagonal_arr_der_fort_der:
    cmp r8, 2
    jle .check_diagonal_arr_izq

    .verificar_diagonal_arr_der_disp:
    mov r11, rdi
    sub r11, 6
    cmp byte [tablero + r11], ' '
    jne .check_diagonal_arr_izq
    mov byte [array_movimientos_posibles + rbp], r11b
    inc rbp

    ; =========
    ; ↖ ↖ ↖ ↖ ↖
    ; =========
    .check_diagonal_arr_izq:
    cmp r10, "^"
    je .check_diagonal_arr_izq_fort_arr
    cmp r10, "<"
    je .check_diagonal_arr_izq_fort_izq
    jmp .finalizar

    .check_diagonal_arr_izq_fort_arr:
    cmp r9, 2 ; columna
    jle .finalizar
    jmp .verificar_diagonal_arr_izq_disp

    .check_diagonal_arr_izq_fort_izq:
    cmp r8, 2 ; fila
    jle .finalizar

    .verificar_diagonal_arr_izq_disp:
    mov r11, rdi
    sub r11, 8
    cmp byte [tablero + r11], ' '
    jne .finalizar
    mov byte [array_movimientos_posibles + rbp], r11b
    inc rbp

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
    mov byte [array_movimientos_posibles + rbp], r11b
    inc rbp

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

    .aspa_arriba:
    .aspa_abajo:

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
