global check_ganador
global juego_terminado

extern printf

extern tablero

; %macro imprimirGanador 0
;     mov     rdi, mensaje_ganador
;     mov     rsi, [ganador]
;     sub     rsp, 8
;     call    printf
;     add     rsp, 8
; %endmacro

section .data

formatoFila db "%s", 0 ; Formato para cada fila
mensaje     db "soldado: ",10,0
mensajeDos  db "oficial: ",10,0
mensajeTres db "Lo que hay en la posicion es: %c",10,0
CANT_FIL	dq	7
CANT_COL	dq	7
LONG_ELEM   dq  1
indice dq	27
es_turno_soldado db 1

section .bss

ganador resq 1 ; (0 = sin ganador, 1 = soldados, 2 = oficiales)

section .text

; retorna:
; - rax: 1 si el juego está terminado, 0 en otro caso.
; - rbx: 1 si el juego fue ganado por los soldados, 0 si fue ganado por los
; oficiales. solo tiene sentido en caso de que rax sea 1.
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

check_ganador:
    mov rdi, [es_turno_soldado]
    mov rsi, tablero
    call encontrar_ganador
    mov [ganador], rax
    ret

; Retorna en RAX al ganador (si lo hay).
; 0 Si no hay.
; 1 Si ganaron los soldados.
; 2 Si ganaron los oficiales.
; Parametros:
;  • rdi - Turno actual(0 = oficiales y 1 = soldados)
;  • rsi - Puntero al tablero
encontrar_ganador:
    mov     r13, rsi ; r13 = puntero al tablero
    mov     r8, rdi ; r8 = turno actual
    xor     r9, r9 ; r9 = ganador

    ; Descomentar las siguientes 2 lineas para devolver que
    ; aun no hay ganador y no probar la logica de este modulo!!!
    ;mov rax, r9
    ;ret

    cmp     r8, 0
    je      .comprobar_fortaleza_ocupada
    cmp     r8, 1
    je      .chequear_si_ganan_oficiales

; Retorna "1" si:
; 1) Todas las posiciones de la fortaleza estan ocupadas
; Si no, comprueba si los oficiales pueden moverse
.comprobar_fortaleza_ocupada:
    mov		rcx,[indice]
    dec		rcx
    imul	rbx,rcx,1
    mov		rax,[rsi+rbx]
    mov     rsi, rax
    mov     rdi, mensajeTres
    call    printf

    jmp .comprobar_oficiales_incapacitados

.comprobar_oficiales_incapacitados:
    mov     rax, 0
    ret
.ganaron_soldados:
    inc     r9
    mov     rax, r9
    ret

; Retorna "2" si:
; 1) Solo queden 8 soldados(o menos)
.chequear_si_ganan_oficiales:
    mov     rax, 0
    ret

.ganaron_oficiales:
    inc     r9
    inc     r9
    mov     rax, r9
    ret
