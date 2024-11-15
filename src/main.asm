global main

extern cargar_movimientos_oficial
extern cargar_movimientos_soldado
extern encontrar_ganador
extern seleccionar_ficha
extern tablero
extern tablero_finalizar
extern tablero_inicializar
extern tablero_renderizar

extern printf
extern scanf

section .data

mensaje_fin db "El juego ha terminado.",10,0
mensaje_turno_soldado db "Turno del soldado.",10,0
mensaje_turno_oficial db "Turno del oficial.",10,0
mensaje_pedir_movimiento db "Ingrese el movimiento del soldado (posición objetivo): ",0
formato_entrada db "%d", 0
mensaje_movimiento_invalido db "El movimiento ingresado es invalido.",10,0

section .bss

juego_activo resb 1     ; Bandera para saber si el juego está activo (1 = activo, 0 = terminado)
es_turno_soldado resb 1 ; Bandera para alternar turnos (1 = soldado, 0 = oficial)
es_movimiento_valido resb 1 ; (0 = invalido, 1 = valido)
ganador resb 1 ; (0 = sin ganador, 1 = soldados, 2 = oficiales)
movimiento_usuario resd 1

section .text

main:
    mov byte [juego_activo], 1 ; Iniciamos el juego
    mov byte [ganador], 0 ; Inicia sin ganador
    mov byte [es_turno_soldado], 0 ; Inicia con el turno del soldado

    call tablero_inicializar ; Cargamos el estado inicial del tablero

.game_loop:
    ; Comprobar si el juego está activo
    cmp byte [juego_activo], 1
    jne .exit ; Si juego_activo es 0, salimos del juego

    ; Mostrar el tablero
    mov rdi,tablero
    call tablero_renderizar

    ; Jugar el turno según corresponda
    cmp byte [es_turno_soldado], 1
    jne .prompt_turno_oficial
    mov rdi, mensaje_turno_oficial

.prompt_turno_soldado:
    mov rdi, mensaje_turno_soldado

.prompt_turno_oficial:
    call printf

.ejecutar_turno:
    ; TODO: Acá viene la parte de Melina, nos termina devolviendo el índice de
    ; la casilla que vamos a mover. Con este valor vamos a llamar a
    ; `cargar_movimientos_soldados` o `cargar_movimientos_oficial` según
    ; corresponda.
    call seleccionar_ficha
    mov rdi, rax

    mov rsi,tablero
    cmp byte [es_turno_soldado], 1
    jne .cargar_movimientos_oficial

.cargar_movimientos_soldado:
    call cargar_movimientos_soldado
    jmp .continue_movimiento

.cargar_movimientos_oficial:
    call cargar_movimientos_oficial

.continue_movimiento:
    call pedir_movimiento
    call validar_movimiento

    ; TODO: Verificar si el juego ha terminado call verificar_si_termino_juego
    ; Asumimos que `verificar_si_termino_juego` pone 0 en [juegoActivo] si
    ; terminó el juego

    ; Cambiar de turno
    mov al, [es_turno_soldado]
    not al
    mov [es_turno_soldado], al

.exit:
    call tablero_finalizar

    mov rdi, mensaje_fin
    call printf

    mov rax,60
    mov rdi,0
    syscall

; (provisional) pido el movimiento del jugador con la casilla correspondiente a la que se quiere mover
pedir_movimiento:
    mov rdi, mensaje_pedir_movimiento
    call printf

    mov rdi, formato_entrada
    mov rsi, movimiento_usuario
    call scanf

    mov rax, [movimiento_usuario]
    mov r8, rax         ; guardo el movimiento del jugador en r8
    ret


; Bucle para recorrer el arreglo de desplazamientos posibles
validar_movimiento:
    ; Comparo si el valor de rbx (subarreglo) es igual al desplazamiento (r8)
    cmp rbx, r8
    je .movimiento_valido

    ; Verifico si se llego al final del arreglo
    cmp rbx, 0
    jz .movimiento_invalido  ; Si el valor es 0, es el final del arreglo, movimiento no válido

    ; Avanzo al siguiente valor en el arreglo de desplazamientos
    add rax, 1
    jmp validar_movimiento

.movimiento_invalido:
    mov byte [es_movimiento_valido], 0
    ret

.movimiento_valido:
    mov byte [es_movimiento_valido], 1
    ret
check_ganador:
    mov rdi, [es_turno_soldado]
    mov rsi, tablero
    call encontrar_ganador
    mov [ganador], rax
    ret
