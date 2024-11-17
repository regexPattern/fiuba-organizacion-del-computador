global cargar_movimientos_oficial

extern array_movimientos_posibles
extern tablero

section .text

cargar_movimientos_oficial:
    ; Calculamos fila y columna
    mov rax, rdi
    mov rcx, 7
    xor rdx, rdx

    div rcx ; rax = fila, rdx = columna
    mov r8, rax ; r8 = fila
    mov r9, rdx ; r9 = columna

    xor rcx, rcx ; rcx = índice del array

.check_limites_arriba:
    ; Si estamos en una columa entre la 2 y la 4 (inclusive) significa que no
    ; estamos en las aspas, por lo tanto, el único límite que nos importa es el
    ; límite superior de todo el tablero.
    ;
    cmp r9, 2
    jl .check_captura_arriba
    cmp r9, 4
    jle .check_captura_arriba

    ; En el caso de estar en las aspas, el límite superior que nos importa es el
    ; de las aspas.
    ;
.check_normal_arriba_aspa_lateral:
    ; Si estamos en las aspas laterales, no permitimos ningun movimiento hacia
    ; arriba en la primera fila.
    ;
    cmp rax, 2
    je .check_limites_abajo

    ; A su vez, si estamos en la segunda fila de las aspas no permitimos
    ; movimientos de captura hacia arriba.
    cmp rax, 3
    je .check_normal_arriba

.check_captura_arriba:
    ; Verificar si hay un soldado directamente arriba
    mov r11, rdi
    sub r11, 7

    cmp BYTE [tablero + r11], 'X'
    jne .check_normal_arriba

    ; Para captura, verificar la siguiente posición
    sub r11, 7 ; r11 ahora tiene la posición después del salto sobre el oficial

    ; Verificar que no nos salimos del tablero
    cmp r11, 0
    jl .check_limites_abajo

    ; Verificar que la posición de salto esta vacía
    cmp byte [tablero + r11], ' '
    jne .check_limites_abajo

    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

    ; Si puedo hacer un movimiento de captura hacia arriba, automáticamente no
    ; puedo hacer un movimiento normal hacia arriba, porque significa que la
    ; celda de arriba está ocupada por un soldado.

.check_normal_arriba:
    ; Verificar si la casilla de arriba está vacía
    mov r11, rdi
    sub r11, 7

    cmp byte [tablero + r11], ' '
    jne .check_limites_abajo
    mov byte [array_movimientos_posibles + rcx], r11b
    inc rcx

.check_limites_abajo:

.finalizar:
    mov r8, 9
    sub r8, rcx ; Calculamos cuántas posiciones nos faltan llenar

    mov r9, rcx ; Guardamos la posición inicial en r9
    mov rcx, r8 ; Movemos a rcx la cantidad de iteraciones para loop

.loop_rellenar:
    mov BYTE [array_movimientos_posibles + r9], 0
    inc r9
    loop .loop_rellenar

    ret
