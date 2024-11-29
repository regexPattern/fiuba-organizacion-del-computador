    global main

    extern fflush
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
    extern tablero_actualizar
    extern encontrar_ganador
    extern tablero_rotar_90

    %macro MENSAJE_RESALTADO 1
    db 10,0x1b,"[38;5;231;48;5;9m",%1,0x1b,"[0m",10,0
    %endmacro

    %macro MENSAJE_ERROR 1
    db 10,0x1b,"[38;5;231;48;5;31m",%1,0x1b,"[0m",10,0
    %endmacro

    %macro MENSAJE_ELEGIR_TURNO 1
    db 10,0x1b,"[38;5;231;48;5;22m",%1,0x1b,"[0m",10,0
    %endmacro

    section .data

    msg_turno_soldado MENSAJE_RESALTADO " Turno del soldado "
    msg_turno_oficial MENSAJE_RESALTADO " Turno del oficial "
    msg_ganador_soldados_fortaleza_llena MENSAJE_RESALTADO " ¡Soldados ganan! (Fortaleza capturada) "
    msg_ganador_soldados_oficiales_rodeados MENSAJE_RESALTADO " ¡Soldados ganan! (Oficiales inmobilizados) "
    msg_ganador_oficiales MENSAJE_RESALTADO " ¡Oficiales ganan! (Soldados diezmados) "
    msg_fin MENSAJE_RESALTADO " El juego ha terminado "
    msg_err_celda_invalida MENSAJE_ERROR " Celda ingresada es inválida - Vuelva a ingresar "
    msg_err_sin_movimientos MENSAJE_ERROR " Ficha seleccionada no tiene movimientos posibles - Elija otra ficha "
    msg_oficial_capturado MENSAJE_RESALTADO " ¡Oficial omitió su captura! "
    msg_elegir_turno MENSAJE_ELEGIR_TURNO " ¿ Quien mueve primero: Oficiales(1) o Soldados(2) ?"
    msg_rotar_tablero MENSAJE_RESALTADO " ¿Desea rotar el tablero? [y/n] "
    msg_entrada_invalida MENSAJE_RESALTADO " Respuesta no válida "
    msg_cuantos_giros MENSAJE_RESALTADO " ¿Cuantos giros de 90° desea realizar? (1, 2 o 3)"

    ansi_limpiar_pantalla db 0x1b,"[2J",0x1b,"[H",0
    msg_continuar_juego db 10,"¿Continuar en el juego? [Y/n]: ",0

    input_salir_del_juego db " %c",0
    input_elegir_primer_jugador db " %c",0
    input_elegir_rotar_tablero db " %c",0
    input_elegir_giros db " %c",0
    prueba db 10,"AAA",0

    section .bss

    juego_activo resb 1 ; bandera para saber si el juego está activo (1 = activo, 0 = terminado)
    es_turno_soldado resb 1 ; bandera para alternar turnos (1 = soldado, 0 = oficial)

    buffer_salir_del_juego resb 1 ; guarda el valor de la respuesta a si se desea salir del juego
    buffer_celda_seleccionada resb 1 ; guarda la celda seleccionada en un turno
    buffer_prox_celda_seleccionada resb 1 ; guarda la celda a la que se va a mover el jugador del turno
    buffer_elegir_primer_jugador resb 1 ; guarda el valor de la respuesta de que jugador empieza
    buffer_elegir_si_rotar resb 1 ; guarda el valor de la respuesta a si se desea rotar el tablero
    buffer_numero_giros resb 1 ; guarda el numero de giros de 90° que se le aplicaran al tablero

    section .text

main:
    mov byte [juego_activo], 1 ; iniciamos el juego

    call tablero_inicializar ; cargamos el estado inicial del tablero

    .game_loop: ; <===== inicio de un turno
    ; limpiamos la pantalla en cada render
    mov rdi, ansi_limpiar_pantalla
    sub rsp, 8
    call printf
    add rsp, 8

    ; renderizamos el tablero sin selecciones
    mov rdi, 0
    call tablero_renderizar
    call elegir_orientacion_tablero
    call elegir_turno
    .inicio_ejecucion_turno: ; <====== acá se regresa en caso de input inválida
    call mostrar_msg_turno
    call seleccionar_celda

    mov byte [buffer_celda_seleccionada], al ; guardamos la celda actual para `.efectuar_movimiento`

    mov rdi, rax
    call validar_celda_seleccionada ; valida = 1, invalida = 0
    cmp rax, 1
    je .celda_valida

    .celda_invalida:
    sub rsp, 8
    mov rdi, msg_err_celda_invalida
    call printf
    add rsp, 8

    jmp .inicio_ejecucion_turno

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
    mov rdi, msg_err_sin_movimientos
    sub rsp, 8
    call printf
    add rsp, 8

    jmp .inicio_ejecucion_turno ; volvemos por input inválida

    ; se selecciona a dónde se va a mover la ficha
    .seleccionar_prox_celda:
    mov rdi, 1
    call tablero_actualizar
    call seleccionar_proxima_celda

    mov byte [buffer_prox_celda_seleccionada], al ; guardamos la celda actual para `.efectuar_movimiento`

    mov rdi, rax
    call validar_prox_celda_seleccionada ; valida = 1, invalida = 0
    cmp rax, 1
    je .efectuar_movimiento

    .efectuar_movimiento:
    movzx rdi, byte [buffer_celda_seleccionada]
    movzx rsi, byte [buffer_prox_celda_seleccionada]

    cmp byte [es_turno_soldado], 1
    jne .mover_oficial

    .mover_soldado:
    call efectuar_movimiento_soldado
    jmp .verificar_estado_juego

    .mover_oficial:
    call efectuar_movimiento_oficial ; retorna rax = 1 si se removió al oficial del tablero (0 si no)
    cmp rax, 1
    jne .verificar_estado_juego

    mov rdi, msg_oficial_capturado
    sub rsp, 8
    call printf
    add rsp, 8

    ; ya cuando efectuamos el turno:
    .verificar_estado_juego:

    ; mostramos el tablero actualizado despues el movimiento
    mov rdi, 0
    call tablero_actualizar

    ; verificamos si el juego ha terminado
    call juego_terminado
    ;
    ; 0 si el juego sigue en curso
    ; 1 si ganaron los soldados llenando la fortaleza
    ; 2 si ganaron los soldados rodeando a los oficiales
    ; 3 si ganaron los oficiales
    ;
    cmp rax, 0 ; juego sigue en curso
    jne .finalizar_juego_ganado

    .continuar_juego:
    ; cambiar de turno y continuar el juego
    mov al, byte [es_turno_soldado]
    xor al, 1
    mov [es_turno_soldado], al

    call mostrar_msg_continuar_juego

    cmp byte [buffer_salir_del_juego], "n"
    je .finalizar ; el usuario explícitamente quiere salir del juego

    jmp .game_loop ; avanzamos al siguiente turno (acá el juego sigue en curso)

    .finalizar_juego_ganado:
    cmp rax, 1 ; ganaron los soldados llenando la fortaleza
    jne .ganador_soldados_oficiales_rodeados
    mov rdi, msg_ganador_soldados_fortaleza_llena
    jmp .mostrar_ganador

    .ganador_soldados_oficiales_rodeados:
    cmp rax, 2 ; ganaron los soldados rodeando a los oficiales
    jne .mostrar_ganador_oficiales
    mov rdi, msg_ganador_soldados_oficiales_rodeados
    jmp .mostrar_ganador

    .mostrar_ganador_oficiales:
    mov rdi, msg_ganador_oficiales

    .mostrar_ganador:
    sub rsp, 8
    call printf
    add rsp, 8

    .finalizar:
    call tablero_finalizar

    mov rdi, msg_fin
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

    ; descripción:
validar_prox_celda_seleccionada:
    ret

    ; descripción:
    ; muestra el mensaje de inicio de turno correspondiente a quien está
    ; ejecutando el turno actualmente
    ;
mostrar_msg_turno:
    cmp byte [es_turno_soldado], 1
    jne .msg_turno_oficiales
    mov rdi, msg_turno_soldado
    jmp .mostrar_msg_turno

.msg_turno_oficiales:
    mov rdi, msg_turno_oficial

.mostrar_msg_turno:
    call printf

    ret

    ; descripción:
    ; imprime el mensaje para salir del juego y pide la respuesta al usuario
    ; para almacenarla en `buffer_salir_del_juego`
    ;
mostrar_msg_continuar_juego:
    mov rdi, msg_continuar_juego
    call printf

    mov rdi, 0
    call fflush

    mov rdi, input_salir_del_juego
    mov rsi, buffer_salir_del_juego
    call scanf

    ret

elegir_turno:
    mov rdi, msg_elegir_turno
    call printf

    mov rdi, 0
    call fflush

    mov rdi, input_elegir_primer_jugador
    mov rsi, buffer_elegir_primer_jugador
    call scanf

    cmp byte [buffer_elegir_primer_jugador], "2"
    je empiezan_los_soldados
    cmp byte [buffer_elegir_primer_jugador], "1"
    je empiezan_los_oficiales

    ret

empiezan_los_soldados:
    mov byte [es_turno_soldado], 1
    ret

empiezan_los_oficiales:
    mov byte [es_turno_soldado], 0
    ret

elegir_orientacion_tablero:
    mov rdi, msg_rotar_tablero
    call printf

    ;call flush

    mov rdi, input_elegir_primer_jugador
    mov rsi, buffer_elegir_si_rotar
    call scanf

    cmp byte[buffer_elegir_si_rotar], "y"
    je .preguntar_giros

    cmp byte[buffer_elegir_si_rotar], "n"
    je .finalizar

    ;si llego aca la respuesta fue invalida
    mov rdi, msg_entrada_invalida
    call printf
    jmp elegir_orientacion_tablero


.preguntar_giros:
    mov rdi, msg_cuantos_giros
    call printf

    lea rdi, input_elegir_giros
    lea rsi, buffer_numero_giros
    call scanf


    ;movzx rax, byte [buffer_numero_giros] ; Cargar el carácter leído en rax
    ;sub rax, '0'
    ;cmp eax, 1
    ;jl .entrada_invalida                ; Si es menor a 1, inválido
    ;cmp eax, 3
    ;jg .entrada_invalida                ; Si es mayor a 3, inválido
    ;mov rcx, rax                        ; para luego usar loop

    mov al, byte [buffer_numero_giros]   ; Cargar el carácter
    cmp al, '1'
    je .giro_1
    cmp al, '2'
    je .giro_2
    cmp al, '3'
    je .giro_3
    jmp .entrada_invalida

.giro_1:
    call tablero_rotar_90
    mov rdi, 0
    sub rsp, 8
    call tablero_actualizar
    add rsp, 8
    jmp .finalizar

.giro_2:
    call tablero_rotar_90
    call tablero_rotar_90
    mov rdi, 0
    call tablero_actualizar
    jmp .finalizar

.giro_3:
    call tablero_rotar_90
    call tablero_rotar_90
    call tablero_rotar_90
    mov rdi, 0
    call tablero_actualizar
    jmp .finalizar

.entrada_invalida:
    mov rdi, msg_entrada_invalida
    call printf
    jmp .preguntar_giros

.finalizar:
    ret
