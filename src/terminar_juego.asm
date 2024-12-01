    global juego_terminado

    extern array_movimientos_posibles
    extern buffer_posicion_fortaleza
    extern cargar_movimientos_oficial
    extern tablero

    section .text

    ; retorna:
    ; - rax: 0 si el juego sigue en curso
    ;        1 si ganaron los soldados llenando la fortaleza
    ;        2 si ganaron los soldados rodeando a los oficiales
    ;        3 si ganaron los oficiales
    ;
juego_terminado:
    ; Primero revisamos si los soldados ocupan todos los puntos del interior de
    ; la fortaleza. Si esto se cumple entonces ganan los soldados. el tema es
    ; que dependiendo de la posicion de la fortaleza, qué columnas y filas
    ; checkeamos cambian
    ;
    mov al, byte [buffer_posicion_fortaleza]

    cmp al, "^"
    jne .check_fortaleza_der
    mov bl, 0 ; índice fila inicial
    mov cl, 2 ; ínidice de columna inicial (se reinicia en cada fila)
    ; la fortaleza siempre es de 3x3, asi que con saber los indices iniciales nos basta
    jmp .loop

    .check_fortaleza_der:
    cmp al, ">"
    jne .check_fortaleza_aba
    mov bl, 2
    mov cl, 4
    jmp .loop

    .check_fortaleza_aba:
    cmp al, "v"
    jne .check_fortaleza_izq
    mov bl, 4
    mov cl, 2
    jmp .loop

    .check_fortaleza_izq:
    mov bl, 2
    mov cl, 0

    .loop:
    ; inicio de los loops
    movzx r8, bl ; índice loop filas
    .loop_filas_fortaleza:
    movzx r9, cl ; índice loop columnas

    .loop_columnas_fortaleza:
    mov r10, r8
    imul r10, 7
    add r10, r9

    ; Si hay alguna casilla del tablero que no sea 'X' entonces esta condición
    ; no está satisfecha aún.
    ;
    cmp byte [tablero + r10], 'X'
    jne .verificar_oficiales_incapacitados

    movzx rax, cl
    add rax, 3 ; llegamos al final del loop, si recorrimos 3 columnas desde la inicial, sea cual sea segun los posicion de la fortaleza
    inc r9
    cmp r9, rax
    jl .loop_columnas_fortaleza

    movzx rax, bl
    add rax, 3 ; lo mismo para las filas
    inc r8
    cmp r8, rax
    jl .loop_filas_fortaleza

    ; Si llegamos acá es porque todos los que están en la fortaleza son soldados
    mov rax, 1
    ret

    ; Si llegamos acá es que hay uno en la fortaleza que no es un soldado. Vamos
    ; a ver verificar la segunda condición en la que ganan los soldados.

    .verificar_oficiales_incapacitados:

    ; Encontramos las posiciones de los oficiales en el tablero, vemos qué
    ; movimientos tiene disponibles cada uno, y si ninguno de los dos tienen
    ; alguno disponible entonces finalizamos el juego.
    ;
    mov r12, 0

    .loop_busqueda_oficial:
    cmp byte [tablero + r12], 'O'
    jne .seguir_buscando_oficial

    ; Si encontramos un oficial, generamos su listado de movimientos posibles
    ; para ver si hay alguno. Cuando encontramos a un oficial con movimientos,
    ; entonces ya sabemos que esta condicion no se cumple.
    ;
    mov rdi, r12
    call cargar_movimientos_oficial
    cmp byte [array_movimientos_posibles], 0
    jne .verificar_oficiales_diezmaron_soldados

    .seguir_buscando_oficial:
    inc r12
    cmp r12, 49
    jl .loop_busqueda_oficial

    ; Si recorrí todo el tablero y no encontré oficiales con movimientos,
    ; entonces ganaron los soldados por inmobilizar a los oficiales
    ;
    mov rax, 2
    ret

    ; Si estamos acá es porque el castillo no está lleno, y hay oficiales con
    ; movimientos, es decir, los soldados no han ganado. Vamos a verificar si
    ; los oficiales han ganado mas bien. La única forma en el que eso puede
    ; pasar es que solo queden 8 soldados.
    ;
    .verificar_oficiales_diezmaron_soldados:
    mov r9, 0 ; contador soldados

    mov r8, 0
    .loop_contar_soldados:
    cmp byte [tablero + r8], 'X'
    jne .seguir_buscando_soldados

    inc r9

    .seguir_buscando_soldados:
    inc r8
    cmp r8, 49
    jl .loop_contar_soldados

    cmp r9, 8
    jg .juego_sigue_en_curso

    ; Si estamos aca es porque quedan menos de 8 soldados (los oficiales
    ; diezmaron a los soldados).
    mov rax, 3
    ret

    .juego_sigue_en_curso:
    mov rax, 0

    ret
