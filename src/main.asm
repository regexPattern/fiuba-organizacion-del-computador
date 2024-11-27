    global main

    extern fclose
    extern fflush
    extern fopen
    extern fread
    extern fwrite
    extern printf
    extern remove
    extern scanf

    extern array_movimientos_posibles
    extern cargar_movimientos_oficial
    extern cargar_movimientos_soldado
    extern efectuar_movimiento_oficial
    extern efectuar_movimiento_soldado
    extern juego_terminado
    extern mostrar_estadisticas
    extern pos_oficial_1
    extern seleccionar_celda
    extern seleccionar_proxima_celda
    extern tablero
    extern tablero_actualizar
    extern tablero_finalizar
    extern tablero_inicializar
    extern tablero_renderizar

    %macro MENSAJE_RESALTADO 1
    db 10,0x1b,"[38;5;231;48;5;9m",%1,0x1b,"[0m",10,0
    %endmacro

    %macro MENSAJE_ERROR 1
    db 10,0x1b,"[38;5;231;48;5;31m",%1,0x1b,"[0m",10,0
    %endmacro

    %macro MENSAJE_PREGUNTA_INICIO 1
    db 10,0x1b,"[38;5;231;48;5;22m",%1,0x1b,"[0m",10,0
    %endmacro

    section .data

    msg_titulo db 10,0x1b,"[2J",0x1b,"[H"
               db "███████╗██╗        █████╗ ███████╗ █████╗ ██╗  ████████╗ ██████╗ ",10
               db "██╔════╝██║       ██╔══██╗██╔════╝██╔══██╗██║  ╚══██╔══╝██╔═══██╗",10
               db "█████╗  ██║       ███████║███████╗███████║██║     ██║   ██║   ██║",10
               db "██╔══╝  ██║       ██╔══██║╚════██║██╔══██║██║     ██║   ██║   ██║",10
               db "███████╗███████╗  ██║  ██║███████║██║  ██║███████╗██║   ╚██████╔╝",10
               db "╚══════╝╚══════╝  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝    ╚═════╝ ",10,0
    msg_fin db 10
            db "███████╗██╗███╗   ██╗",10
            db "██╔════╝██║████╗  ██║",10
            db "█████╗  ██║██╔██╗ ██║",10
            db "██╔══╝  ██║██║╚██╗██║",10
            db "██║     ██║██║ ╚████║",10
            db "╚═╝     ╚═╝╚═╝  ╚═══╝",10,0
    msg_turno_soldado MENSAJE_RESALTADO " Turno del soldado "
    msg_turno_oficial MENSAJE_RESALTADO " Turno del oficial "
    msg_ganador_soldados_fortaleza_llena MENSAJE_RESALTADO " ¡Soldados ganan! (Fortaleza capturada) "
    msg_ganador_soldados_oficiales_rodeados MENSAJE_RESALTADO " ¡Soldados ganan! (Oficiales inmobilizados) "
    msg_ganador_oficiales MENSAJE_RESALTADO " ¡Oficiales ganan! (Soldados diezmados) "
    msg_err_celda_invalida MENSAJE_ERROR " Celda ingresada es inválida - Vuelva a ingresar "
    msg_err_sin_movimientos MENSAJE_ERROR " Ficha seleccionada no tiene movimientos posibles - Elija otra ficha "
    msg_oficial_capturado MENSAJE_RESALTADO " ¡Oficial omitió su captura! "
    msg_elegir_turno MENSAJE_PREGUNTA_INICIO " ¿Quien mueve primero? (Oficiales=1 o Soldados=2) "
    msg_err_seleccion MENSAJE_ERROR " Opción seleccionada no es válida "
    msg_partida_anterior_encontrada MENSAJE_PREGUNTA_INICIO " ¿Continuar partida anterior? (Si=1 o Nueva Partida=2) "
    msg_seleccion_opcion db 10," - Seleccione una opción: ",0
    msg_estadisticas MENSAJE_RESALTADO " Estadísticas del juego "

    ansi_limpiar_pantalla db 0x1b,"[2J",0x1b,"[H",0
    msg_continuar_juego db 10,"¿Continuar en el juego? [Y/n]: ",0

    input_salir_del_juego db " %c",0
    input_elegir_primer_jugador db " %c",0
    input_cargar_partida db " %c",0

    path_archivo_partida db "partida.dat",0
    modo_lectura_archivo_partida db "rb",0
    modo_escritura_archivo_partida db "wb+",0

    section .bss

    juego_activo resb 1 ; bandera para saber si el juego está activo (1 = activo, 0 = terminado)
    es_turno_soldado resb 1 ; bandera para alternar turnos (1 = soldado, 0 = oficial)

    buffer_salir_del_juego resb 1 ; guarda el valor de la respuesta a si se desea salir del juego
    buffer_celda_seleccionada resb 1 ; guarda la celda seleccionada en un turno
    buffer_prox_celda_seleccionada resb 1 ; guarda la celda a la que se va a mover el jugador del turno
    buffer_elegir_primer_jugador resb 1 ; guarda el valor de la respuesta de que jugador empieza
    buffer_cargar_partida resb 1 ; guardar el valor de la respuesta de la carga de partida anterior

    file_desc_archivo_partida resq 1 ; file descriptor archivo partida

    section .text

main:
    mov byte [juego_activo], 1 ; iniciamos el juego

    mov rdi, msg_titulo
    sub rsp, 8
    call printf
    add rsp, 8

    call cargar_partida

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
    je .interrumpir_juego ; el usuario explícitamente quiere salir del juego

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

    ; eliminamos el archivo de la partida en progreso si hay alguna, ya que la
    ; partida se terminó
    mov rdi, path_archivo_partida
    call remove
    jmp .finalizar

    .interrumpir_juego:
    call guardar_partida

    .finalizar:
    call tablero_finalizar

    mov rdi, msg_estadisticas
    sub rsp, 8
    call printf
    add rsp, 8

    call mostrar_estadisticas

    mov rdi, msg_fin
    sub rsp, 8
    call printf
    add rsp, 8

    ; exit syscall
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

cargar_partida:
    mov rdi, path_archivo_partida
    mov rsi, modo_lectura_archivo_partida
    call fopen

    cmp rax, 0 ; en este caso no se abrió el archivo
    je .nueva_partida

    ; si encontre un archivo, me guardo el file descriptor, aunque puede ser
    ; que el usuario decida no cargar la partida anterior
    ;
    mov [file_desc_archivo_partida], rax

    mov rdi, msg_partida_anterior_encontrada
    call printf

    .seleccion_opcion:
    mov rdi, msg_seleccion_opcion
    call printf

    mov rdi, input_cargar_partida
    mov rsi, buffer_cargar_partida
    call scanf

    mov al, byte [buffer_cargar_partida]
    cmp al, "1"
    je .cargar_partida_anterior
    cmp al, "2"
    je .nueva_partida

    mov rdi, msg_err_seleccion
    call printf
    jmp .seleccion_opcion

    .cargar_partida_anterior:
    ; leemos quien tiene el proximo turno
    mov rdi, es_turno_soldado
    mov rsi, 1
    mov rdx, 1
    mov rcx, [file_desc_archivo_partida]
    call fread

    ; leemos las fichas del tablero
    mov rdi, tablero
    mov rsi, 1
    mov rdx, 49
    mov rcx, [file_desc_archivo_partida]
    call fread

    ; leemos las estadisticas de los oficiales
    mov rdi, pos_oficial_1
    mov rsi, 1
    mov rdx, 38
    mov rcx, [file_desc_archivo_partida]
    call fread

    ret

    .nueva_partida:
    ; eliminamos el archivo de partida anterior
    ; TODO: en este caso deberiamos iniciar con los valores por defecto? Si,
    ; pero no hay necesidad de generarlos dinamicamente aca o si? Probablemente
    ; si, en funcion de la customizacion que se elija
    mov rdi, path_archivo_partida
    call remove

    sub rsp, 8
    call elegir_turno
    add rsp, 8

    ret

elegir_turno:
    mov rdi, msg_elegir_turno
    call printf

    .seleccion_opcion:
    mov rdi, msg_seleccion_opcion
    call printf

    mov rdi, input_elegir_primer_jugador
    mov rsi, buffer_elegir_primer_jugador
    call scanf

    cmp byte [buffer_elegir_primer_jugador], "2"
    je .empiezan_los_soldados
    cmp byte [buffer_elegir_primer_jugador], "1"
    je .empiezan_los_oficiales

    mov rdi, msg_err_seleccion
    call printf
    jmp .seleccion_opcion

    .empiezan_los_soldados:
    mov byte [es_turno_soldado], 1
    ret

    .empiezan_los_oficiales:
    mov byte [es_turno_soldado], 0
    ret

guardar_partida:
    mov rdi, path_archivo_partida
    mov rsi, modo_escritura_archivo_partida
    call fopen
    mov [file_desc_archivo_partida], rax

    ; guardado de quien tiene el proximo turno
    mov rdi, es_turno_soldado ; ya en este momento se cambió al siguiente
    mov rsi, 1
    mov rdx, 1
    mov rcx, [file_desc_archivo_partida]
    call fwrite

    ; guardado de las fichas del tablero
    mov rdi, tablero
    mov rsi, 1
    mov rdx, 49
    mov rcx, [file_desc_archivo_partida]
    call fwrite

    ; guardado de las estadisticas de los oficiales
    mov rdi, pos_oficial_1
    mov rsi, 1
    mov rdx, 38
    mov rcx, [file_desc_archivo_partida]
    call fwrite

    mov rdi, [file_desc_archivo_partida]
    call fclose

    ret
