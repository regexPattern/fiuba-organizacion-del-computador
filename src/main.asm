global main

extern movimientos_soldados
extern tablero_inicializar
extern tablero_renderizar
extern tablero_finalizar

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

section .text
main:
    ; Inicializamos todo para arrancar el juego en un estado jugable.
    mov byte [juego_activo], 1 ; Iniciamos el juego

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
    mov rdi,31
    mov rsi,tablero
    call movimientos_soldados

    ret
