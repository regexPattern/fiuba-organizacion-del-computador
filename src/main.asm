global main

extern printf
extern scanf

extern ansi_celda_seleccionada
extern array_movimientos_posibles
extern cargar_movimientos_oficial
extern cargar_movimientos_soldado
extern juego_terminado
extern seleccionar_celda
extern seleccionar_proxima_celda
extern tablero
extern tablero_finalizar
extern tablero_inicializar
extern tablero_renderizar

%macro MENSAJE_RESALTADO 1
    db 10,0x1b,"[38;5;231;48;5;9m",%1,0x1b,"[0m",10,0
%endmacro

%macro MENSAJE_ERROR 1
    db 10,0x1b,"[38;5;231;48;5;31m",%1,0x1b,"[0m",10,0
%endmacro

section .data

mensaje_fin MENSAJE_RESALTADO " EL JUEGO HA TERMINADO "
mensaje_turno_soldado MENSAJE_RESALTADO " TURNO DEL SOLDADO "
mensaje_turno_oficial MENSAJE_RESALTADO " TURNO DEL OFICIAL "
mensaje_ganador_soldados MENSAJE_RESALTADO " ¡SOLDADOS GANAN! "
mensaje_ganador_oficiales MENSAJE_RESALTADO " ¡OFICIALES GANAN! "

mensaje_err_celda_invalida MENSAJE_ERROR " CELDA INGRESADA ES INVÁLIDA - VUELVA A INGRESAR "
mensaje_err_sin_movimientos MENSAJE_ERROR " FICHA SELECCIONADA NO TIENE MOVIMIENTOS - ELIJA OTRA FICHA "

mensaje_salir_del_juego db 10,"¿Desea salir del juego? [y/N]: ",0
mensaje_celdas_disponibles_mov db " Celdas marcadas como disponibles",10,10,0

input_scanf_salir_del_juego db "%c",0

section .bss

juego_activo resb 1 ; bandera para saber si el juego está activo (1 = activo, 0 = terminado)
es_turno_soldado resb 1 ; bandera para alternar turnos (1 = soldado, 0 = oficial)

puntero_mensaje_turno resq 1 ; permite reutilizar el codigo que imprime el letrero del turno actual
buffer_salir_del_juego resb 1 ; guarda el valor de la respuesta a si se desea salir del juego

section .text

main:
    mov byte [juego_activo], 1 ; iniciamos el juego
    mov byte [es_turno_soldado], 1 ; inicia con el turno del soldado

    call tablero_inicializar ; cargamos el estado inicial del tablero

.game_loop: ; inicio de un turno
    ; al inicio de cada loop no tenemos celdas seleccionadas entonces paso un
    ; puntero NULL
    ;
    mov rdi, 0
    call tablero_renderizar

    ; jugar el turno según corresponda
    cmp byte [es_turno_soldado], 1
    jne .mensaje_turno_oficial

.mensaje_turno_soldado:
    mov qword [puntero_mensaje_turno], mensaje_turno_soldado
    jmp .continue_mensaje_inicio_turno

.mensaje_turno_oficial:
    mov qword [puntero_mensaje_turno], mensaje_turno_oficial

.continue_mensaje_inicio_turno:
    sub rsp, 8
    mov rdi, [puntero_mensaje_turno]
    call printf
    add rsp, 8

.seleccionar_celda:
    call seleccionar_celda

    mov rdi, rax
    call validar_celda_seleccionada ; valida = 1, invalida = 0
    cmp rax, 1
    je .celda_valida

.celda_invalida:
    sub rsp, 8
    mov rdi, mensaje_err_celda_invalida
    call printf
    add rsp, 8

    jmp .continue_mensaje_inicio_turno

.celda_valida:
    ; ya tengo rdi = rax = celda seleccionada
    cmp byte [es_turno_soldado], 1
    jne .cargar_movimientos_oficial

.cargar_movimientos_soldado:
    call cargar_movimientos_soldado
    jmp .validar_ficha_tiene_movimientos

.cargar_movimientos_oficial:
    call cargar_movimientos_oficial

.validar_ficha_tiene_movimientos:
    cmp byte [array_movimientos_posibles], 0
    jne .seleccionar_prox_celda

.ficha_no_tiene_movimientos:
    sub rsp, 8
    mov rdi, mensaje_err_sin_movimientos
    call printf
    add rsp, 8

    jmp .continue_mensaje_inicio_turno

.seleccionar_prox_celda:
    ; en rax está el puntero al array de movimientos (sea cual sea), lo vamos a
    ; utilizar tanto para renderizar las opciones posibles como para comprobar
    ; si la opcion ingresada es una de estas opciones.
    ;
    push rax

    sub rsp, 8

    mov rdi, array_movimientos_posibles
    call tablero_renderizar

    sub rsp, 8

    mov rdi, [puntero_mensaje_turno]
    call printf

    mov rdi, ansi_celda_seleccionada
    mov rsi, " "
    call printf

    mov rdi, mensaje_celdas_disponibles_mov
    call printf

    add rsp, 16

    pop rdi ; el valor puntero al array que guardamos ya queda listo en rdi

    call seleccionar_proxima_celda

    ; TODO: falta toda la parte de efectivamente mover las piezas, eliminar los
    ; soldados que fueron atrapados y eliminar a los oficiales que no capturaron
    ; a los soldados.

.verificar_estado_juego:
    call juego_terminado
    cmp rax, 1

    ; en este momento rbx va tener 1 si el juego fue ganador por los soldados y
    ; 0 si fue ganado por los oficiales.
    ;
    je .finalizar_juego_ganado

.continuar_juego:
    ; cambiar de turno y continuar el juego
    mov al, [es_turno_soldado]
    not al
    mov [es_turno_soldado], al

    sub rsp, 8

    mov rdi, mensaje_salir_del_juego
    call printf

    mov rdi, input_scanf_salir_del_juego
    mov rsi, buffer_salir_del_juego
    call scanf

    cmp byte [buffer_salir_del_juego], "y"
    je .finalizar

    add rsp, 8

    cmp byte [buffer_salir_del_juego], "y"
    jne .game_loop

.finalizar_juego_ganado:
    cmp rbx, 1 ; juego_terminado nos devolvio este valor
    jne .mostrar_ganador_oficiales

.mostrar_ganador_soldados:
    mov rdi, mensaje_ganador_soldados
    jmp .mostrar_ganador

.mostrar_ganador_oficiales:
    mov rdi, mensaje_ganador_oficiales

.mostrar_ganador:
    sub rsp, 8
    call printf
    add rsp, 8

.finalizar:
    call tablero_finalizar

    mov rdi, mensaje_fin

    sub rsp, 8
    call printf
    add rsp, 8

    mov rax,60
    mov rdi,0
    syscall

; parametros:
; - rdi - celda seleccionada
;
validar_celda_seleccionada:
    cmp byte [es_turno_soldado], 1
    jne .validar_celda_es_oficial

.validar_celda_es_soldado:
    cmp byte [tablero + rdi], "X"
    jmp .validar

.validar_celda_es_oficial:
    cmp byte [tablero + rdi], "O"

.validar:
    jne .celda_invalida

.celda_valida:
    mov rax, 1
    jmp .finalizar

.celda_invalida:
    mov rax, 0

.finalizar:
    ret

validar_prox_celda_seleccionada:
    ret
