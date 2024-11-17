    global main

    extern printf
    extern scanf

    extern ansi_celda_seleccionada
    extern array_movimientos_posibles
    extern cargar_movimientos_oficial
    extern cargar_movimientos_soldado
    extern efectuar_movimiento_oficial
    extern efectuar_movimiento_soldado
    extern juego_terminado
    extern seleccionar_celda
    extern seleccionar_proxima_celda
    extern tablero
    extern tablero_finalizar
    extern tablero_inicializar
    extern tablero_renderizar

    %macro MENSAJE_RESALTADO 1
    db 10,0x1b,"[38;5;0;48;5;9m",%1,0x1b,"[0m",10,0
    %endmacro

    %macro MENSAJE_ERROR 1
    db 10,0x1b,"[38;5;0;48;5;31m",%1,0x1b,"[0m",10,0
    %endmacro

    section .data

    mensaje_fin MENSAJE_RESALTADO " El juego ha terminado "
    mensaje_turno_soldado MENSAJE_RESALTADO " Turno del soldado "
    mensaje_turno_oficial MENSAJE_RESALTADO " Turno del oficial "
    mensaje_ganador_soldados MENSAJE_RESALTADO " ¡Soldados ganan! "
    mensaje_ganador_oficiales MENSAJE_RESALTADO " ¡Oficiales ganan! "

    mensaje_err_celda_invalida MENSAJE_ERROR " Celda ingresada es inválida - Vuelva a ingresar "
    mensaje_err_sin_movimientos MENSAJE_ERROR " Ficha seleccionada no tiene movimientos posibles - Elija otra ficha "

    mensaje_salir_del_juego db 10,"¿Desea salir del juego? [y/N]: ",0
    mensaje_celdas_disponibles_mov db " Celdas marcadas como disponibles",10,10,0

    input_salir_del_juego db "%c",0
    salto_linea db 10,0

    section .bss

    juego_activo resb 1 ; bandera para saber si el juego está activo (1 = activo, 0 = terminado)
    es_turno_soldado resb 1 ; bandera para alternar turnos (1 = soldado, 0 = oficial)

    puntero_mensaje_turno resq 1 ; permite reutilizar el codigo que imprime el letrero del turno actual
    buffer_salir_del_juego resb 1 ; guarda el valor de la respuesta a si se desea salir del juego

    celda_seleccionada resb 1
    prox_celda_seleccionada resb 1

    section .text

main:
    mov byte [juego_activo], 1 ; iniciamos el juego
    mov byte [es_turno_soldado], 1 ; inicia con el turno del soldado

    call tablero_inicializar ; cargamos el estado inicial del tablero

    .game_loop: ; <===== inicio de un turno
    mov rdi, 0
    call tablero_renderizar

    ; jugar el turno según corresponda
    cmp byte [es_turno_soldado], 1
    jne .mensaje_turno_oficial

    .mensaje_turno_soldado:
    mov qword [puntero_mensaje_turno], mensaje_turno_soldado
    jmp .mostrar_mensaje_inicio_turno

    .mensaje_turno_oficial:
    mov qword [puntero_mensaje_turno], mensaje_turno_oficial

    .mostrar_mensaje_inicio_turno: ; <====== acá se regresa en caso de input inválida
    mov rdi, [puntero_mensaje_turno]
    sub rsp, 8
    call printf
    add rsp, 8

    ; se selecciona la ficha que se va a mover
    .seleccionar_celda:
    call seleccionar_celda

    mov byte [celda_seleccionada], al ; guardamos la celda actual para `.efectuar_movimiento`

    mov rdi, rax
    call validar_celda_seleccionada ; valida = 1, invalida = 0
    cmp rax, 1
    je .celda_valida

    .celda_invalida:
    sub rsp, 8
    mov rdi, mensaje_err_celda_invalida
    call printf
    add rsp, 8

    jmp .mostrar_mensaje_inicio_turno

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
    ; si el primer byte del arreglo de movimientos posibles es 0, entonces la
    ; ficha no tiene movimientos posibles
    ;
    cmp byte [array_movimientos_posibles], 0
    jne .seleccionar_prox_celda

    .ficha_no_tiene_movimientos:
    mov rdi, mensaje_err_sin_movimientos
    sub rsp, 8
    call printf
    add rsp, 8

    jmp .mostrar_mensaje_inicio_turno ; volvemos por input inválida

    ; se selecciona a dónde se va a mover la ficha
    .seleccionar_prox_celda:
    mov rdi, 1
    call tablero_renderizar

    sub rsp, 8

    mov rdi, [puntero_mensaje_turno]
    call printf

    mov rdi, salto_linea
    call printf

    mov rdi, ansi_celda_seleccionada
    mov rsi, " "
    call printf

    mov rdi, mensaje_celdas_disponibles_mov
    call printf

    add rsp, 8

    call seleccionar_proxima_celda ; <===== hasta acá se hace la selección

    mov byte [prox_celda_seleccionada], al ; guardamos la celda actual para `.efectuar_movimiento`

    mov rdi, rax
    call validar_prox_celda_seleccionada ; valida = 1, invalida = 0
    cmp rax, 1
    je .efectuar_movimiento ; TODO: manejar el caso negativo, falta validar si es una de las celdas que esta en el array de movimientos posibles

    .efectuar_movimiento:
    movzx rdi, byte [celda_seleccionada]
    movzx rsi, byte [prox_celda_seleccionada]

    cmp byte [es_turno_soldado], 1
    jne .mover_oficial

    .mover_soldado:
    call efectuar_movimiento_soldado
    jmp .verificar_estado_juego

    .mover_oficial:
    call efectuar_movimiento_oficial

    ; ya cuando efectuamos el turno:
    .verificar_estado_juego:
    call juego_terminado
    cmp rax, 1 ; 1 = juego terminado, 0 = juego no terminado

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

    mov rdi, input_salir_del_juego
    mov rsi, buffer_salir_del_juego
    call scanf

    add rsp, 8

    cmp byte [buffer_salir_del_juego], "y"
    je .finalizar ; el usuario explícitamente quiere salir del juego

    jmp .game_loop ; avanzamos al siguiente turno

    .finalizar_juego_ganado:
    cmp rbx, 1 ; `juego_terminado` nos devolvió este valor
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

    ; parámetros:
    ; - rdi: índice de la celda seleccionada
    ;
    ; retorna:
    ; - rax: 1 si la celda seleccionada es válida. (esta validación solo implica que
    ;   haya una ficha que pueda ser jugada por el turno actual en la celda
    ;   seleccionada, luego se deben hacer otras validaciones de ser necesarias, por
    ;   ejemplo, para ver si la ficha seleccionada tiene movimientos disponibles).
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
