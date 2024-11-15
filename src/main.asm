global main

extern movimientos_soldados
extern movimientos_oficiales
extern tablero_inicializar
extern tablero_renderizar
extern tablero_finalizar
extern encontrar_ganador

extern printf

section .data
tablero db ' ', ' ', 'X', 'X', 'X', ' ', ' '
        db ' ', ' ', 'X', 'X', 'X', ' ', ' '
        db 'X', 'X', 'X', 'X', 'X', 'X', 'X'
        db 'X', 'X', 'X', 'X', 'X', 'X', 'X'
        db 'X', 'X', ' ', 'X', ' ', 'X', 'X'
        db ' ', ' ', ' ', ' ', 'O', ' ', ' '
        db ' ', ' ', 'O', ' ', ' ', ' ', ' '

mensaje_fin db "El juego ha terminado.",10,0
mensaje_turno_soldado db "Turno del soldado.",10,0
mensaje_turno_oficial db "Turno del oficial.",10,0

section .bss
juego_activo resb 1     ; Bandera para saber si el juego está activo (1 = activo, 0 = terminado)
es_turno_soldado resb 1 ; Bandera para alternar turnos (1 = soldado, 0 = oficial)
ganador resb 1 ; (0 = sin ganador, 1 = soldados, 2 = oficiales)

section .text
main:
    ; Inicializamos todo para arrancar el juego en un estado jugable.
    mov byte [juego_activo], 1 ; Iniciamos el juego

    mov byte [ganador], 0 ; Inicia sin ganador

    call tablero_inicializar ; Cargamos el estado inicial del tablero

    mov byte [es_turno_soldado], 1 ; Inicia con el turno del soldado

.game_loop:
    ; Comprobar si el juego está activo
    cmp byte [juego_activo], 1
    jne .exit ; Si juego_activo es 0, salimos del juego

    ; Mostrar el tablero
    mov rdi,tablero
    call tablero_renderizar

    ; Jugar el turno según corresponda
    cmp byte [es_turno_soldado], 1
    jne .turno_oficial
    mov rdi, mensaje_turno_oficial

.turno_soldado:
    mov rdi, mensaje_turno_soldado

.turno_oficial:
    call printf

.realizar_turno:
    ; Llamar a jugar_turno (maneja el turno del jugador actual)
    ; `jugar_turno` espera que [es_turno_soldado] determine si es el turno del soldado
    call jugar_turno

    jmp check_ganador
    ; Queda guardado en [ganador] quien gana

    ; Verificar si el juego ha terminado
    ; call verificar_si_termino_juego
    ; Asumimos que `verificar_si_termino_juego` pone 0 en [juegoActivo] si terminó el juego

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

jugar_turno:
    ; Acá tenemos que pasar el índice de la celda seleccionada, vendría a ser
    ; toda la parte de Melina.
    mov rdi,31

    mov rsi,tablero

    cmp byte [es_turno_soldado], 1
    jne .mover_oficial

.mover_soldado:
    call movimientos_soldados
    jmp .continue_movimiento

.mover_oficial:
    call movimientos_oficiales

.continue_movimiento:
    ; Acá vendría la parte de Gero.
    ; Los movimientos de la siguiente ficha quedan en rax, no importa si es
    ; oficial o soldado, ya se tiene el arreglo de posiciones válidas.
    ;
    ; Hay que ver cómo hacemos que efectivamente se tomen las acciones que haya
    ; que tomarse en el movimiento: eliminar un soldado o un oficial.

    ret

check_ganador:
    mov rdi, tablero
    mov rsi, [es_turno_soldado]
    call encontrar_ganador
    mov [ganador], rax
    ret