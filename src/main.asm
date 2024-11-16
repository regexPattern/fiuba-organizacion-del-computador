global main

extern printf
extern scanf

extern array_celdas_seleccionadas
extern cargar_movimientos_oficial
extern cargar_movimientos_soldado
extern check_ganador
extern seleccionar_celda
extern seleccionar_proxima_celda
extern tablero
extern tablero_finalizar
extern tablero_inicializar
extern tablero_renderizar

section .data

mensaje_fin db "El juego ha terminado.",10,0
mensaje_turno_soldado db 10,0x1b,"[38;5;231;48;5;9m"," TURNO DEL SOLDADO ",0x1b,"[0m",10,10,0
mensaje_turno_oficial db 10,0x1b,"[38;5;231;48;5;9m"," TURNO DEL OFICIAL ",0x1b,"[0m",10,10,0
mensaje_movimiento_invalido db "El movimiento ingresado es invalido.",10,0
mensaje_ganador db "El ganador es: %lli",10,0

section .bss

juego_activo resb 1 ; Bandera para saber si el juego está activo (1 = activo, 0 = terminado)
es_turno_soldado resb 1 ; Bandera para alternar turnos (1 = soldado, 0 = oficial)

section .text

main:
    mov byte [juego_activo], 1 ; iniciamos el juego
    ; mov byte [ganador], 0 ; inicia sin ganador
    mov byte [es_turno_soldado], 1 ; inicia con el turno del soldado

    call tablero_inicializar ; cargamos el estado inicial del tablero

.game_loop:
    ; comprobar si el juego está activo
    cmp byte [juego_activo], 1
    jne .finalizar ; si juego_activo es 0, salimos del juego

    ; al inicio de cada loop no tenemos celdas seleccionadas entonces paso un
    ; puntero NULL
    ;
    mov rdi, 0
    call tablero_renderizar

    ; call check_ganador
    ; imprimirGanador

    ; jugar el turno según corresponda
    cmp byte [es_turno_soldado], 1
    jne .prompt_turno_oficial

.prompt_turno_soldado:
    mov rdi, mensaje_turno_soldado
    jmp .continue_prompt_inicio_turno

.prompt_turno_oficial:
    mov rdi, mensaje_turno_oficial

.continue_prompt_inicio_turno:
    sub rsp, 8
    call printf
    add rsp, 8

.ejectuar_turno:
    ; TODO: Acá viene la parte de Melina, nos termina devolviendo el índice de
    ; la casilla que vamos a mover. Con este valor vamos a llamar a
    ; `cargar_movimientos_soldados` o `cargar_movimientos_oficial` según
    ; corresponda.
    ;
    call seleccionar_celda

    push rax
    sub rsp, 8

    mov byte [array_celdas_seleccionadas], 33 ; TODO, esto me lo deberia devolver seleccionar_celda
    mov rdi, array_celdas_seleccionadas
    call tablero_renderizar

    add rsp, 8
    pop rdi

    mov rsi, tablero

    cmp byte [es_turno_soldado], 1
    jne .cargar_movimientos_oficial

.cargar_movimientos_soldado:
    call cargar_movimientos_soldado
    jmp .continue_movimiento

.cargar_movimientos_oficial:
    call cargar_movimientos_oficial

.continue_movimiento:
    ; en rax está el puntero al array de movimientos (sea cual sea), lo vamos a
    ; utilizar tanto para renderizar las opciones posibles como para comprobar
    ; si la opcion ingresada es una de estas opciones.
    ;
    push rax
    sub rsp, 8

    mov rdi, 0
    call tablero_renderizar

    add rsp, 8
    pop rdi ; el valor puntero al array que guardamos ya queda listo en rdi

    call seleccionar_proxima_celda

    ; TODO: Verificar si el juego ha terminado call verificar_si_termino_juego
    ; Asumimos que `verificar_si_termino_juego` pone 0 en [juegoActivo] si
    ; terminó el juego
    ;
    ; call check_ganador

    ; cambiar de turno
    mov al, [es_turno_soldado]
    not al
    mov [es_turno_soldado], al

.finalizar:
    call tablero_finalizar

    mov rdi, mensaje_fin
    call printf

    mov rax,60
    mov rdi,0
    syscall
