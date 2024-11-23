    global encontrar_ganador
    global juego_terminado

    extern printf
    extern array_movimientos_posibles
    extern cargar_movimientos_oficial
    extern tablero

    ;%macro imprimirGanador 0
    ;    mov     rdi, mensaje_ganador
    ;    mov     rsi, [ganador]
    ;    sub     rsp, 8
    ;    call    printf
    ;    add     rsp, 8
    ;%endmacro

    section .data

    formatoFila     db "%s", 0 ; Formato para cada fila
    mensaje         db "soldado: ",10,0
    mensajeDos      db "oficial: ",10,0
    mensajeTres     db "Oficial libre en posicion: %i",10,0
    CANT_FIL	    dq	7
    CANT_COL	    dq	7
    LONG_ELEM       dq  1
    indiceFortaleza dq	31
    indiceTablero   dq  0

    section .bss

    section .text

    ; retorna:
    ; - rax: 1 si el juego está terminado, 0 en otro caso.
    ; - rbx: 1 si el juego fue ganado por los soldados, 0 si fue ganado por los
    ;   oficiales. solo tiene sentido en caso de que rax sea 1.
    ;
juego_terminado:
    ; el valor por defecto es que no ha termino, a menos que encontremos una
    ; condición que nos diga que si finalizó, devolvemos esto
    ;
    mov rax, 0

    ; primero revisamos si los soldados ocupan todos los puntos del interior de
    ; la fortaleza.
    ;
    .verificar_soldados_en_fortaleza:
    mov r8, 4

    .loop_filas_fortaleza:
    mov r9, 3

    .loop_columnas_fortaleza:
    mov r10, r8
    imul r10, 7
    add r10, r9

    cmp byte [tablero + r10], 'X'
    jne .hay_uno_que_no_es_soldado

    inc r9
    cmp r9, 6
    jl .loop_columnas_fortaleza

    inc r8
    cmp r8, 7
    jl .loop_filas_fortaleza

    .todos_son_soldados:
    mov rax, 1
    jmp .finalizar

    .hay_uno_que_no_es_soldado:

    .finalizar:
    ret

; Retorna en RAX al ganador (si lo hay).
; 0 Si no hay.
; 1 Si ganaron los soldados.
; 2 Si ganaron los oficiales.
; Parametros:
;  • rdi - Turno actual(0 = oficiales y 1 = soldados)
encontrar_ganador:
    cmp     rdi, 0
    je      chequear_si_ganan_soldados
    cmp     rdi, 1
    je      chequear_si_ganan_oficiales

; Retorna "1" si:
; 1) Todas las posiciones de la fortaleza estan ocupadas
; Si no, comprueba si los oficiales pueden moverse
chequear_si_ganan_soldados:
    sub     rsp, 8
    call    chequear_fortaleza_ocupada
    add     rsp,8
    cmp     rax, 1
    je      ganaron_soldados

    sub     rsp, 8
    call    chequear_oficiales_incapacitados
    add     rsp,8
    cmp     rax, 1
    je      ganaron_soldados

    xor     rax, rax
    ret

chequear_fortaleza_ocupada:
    mov		rcx,[indiceFortaleza]
    dec		rcx
    imul	rbx,rcx,1
    mov     r14, 5 ; Fortaleza empieza en la fila 5
    .iterar_por_fila:
    mov     r15, 3  ; Fortaleza empieza en la columna 3
    .iterar_por_columna:
    cmp     byte [tablero+rbx], ' '
    je      no_esta_ocupada
    inc     rbx
    add     r15, 1
    cmp     r15, 6 ; Finaliza si se pasa de la columna 5
    jne     .iterar_por_columna
    inc     r14
    add     rbx, 4
    cmp     r14, 8 ; Finaliza si se pasa de la fila 7
    jne     .iterar_por_fila

    mov     rax, 1
    ret

no_esta_ocupada:
    mov     rax, 0
    ret

;Retorna 1 si despues de iterar el tablero no existe algun oficial
;que tenga movimientos posibles
chequear_oficiales_incapacitados:
    mov		r13,[indiceTablero]
    .loopTablero:
    cmp     byte [tablero+r13], 'O'
    je      .verificar_oficial_libre
    .seguir_buscando:
    inc     r13
    cmp     r13, 49
    jl      .loopTablero
    mov     rax, 1
    ret

    .verificar_oficial_libre:
    mov     rdi, r13
    call    cargar_movimientos_oficial
    cmp     byte [array_movimientos_posibles], 0
    jne     oficial_libre
    jmp     .seguir_buscando

oficial_libre:
    xor     rax, rax
    ret

ganaron_soldados:
    mov     rax, 1
    ret

; Retorna "2" si:
; 1) Solo queden 8 soldados(o menos)
chequear_si_ganan_oficiales:
    mov		r13,[indiceTablero]
    xor     r14, r14
    .loopTablero:
    cmp     byte [tablero+r13], 'X'
    je      .contabilizar_soldado
    .seguir_buscando:
    inc     r13
    cmp     r13, 49
    jl      .loopTablero
    cmp     r14, 8
    jle     ganaron_oficiales
    xor     rax, rax
    ret

    .contabilizar_soldado:
    inc     r14
    jmp     .seguir_buscando

ganaron_oficiales:
    mov     rax, 2
    ret
