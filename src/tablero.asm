    global ansi_celda_seleccionada
    global tablero
    global tablero_actualizar
    global tablero_finalizar
    global tablero_inicializar
    global tablero_renderizar

    extern fclose
    extern fopen
    extern fread
    extern printf
    extern rewind
    extern scanf

    extern array_movimientos_posibles

    %define CANTIDAD_COLUMNAS 7
    %define LONGITUD_CELDA_ASCII 29

    section .data

    tablero db ' ', ' ', ' ', ' ', ' ', ' ', ' '
            db ' ', ' ', ' ', ' ', ' ', ' ', ' '
            db ' ', ' ', 'X', 'X', ' ', ' ', ' '
            db ' ', ' ', ' ', ' ', ' ', ' ', ' '
            db ' ', 'X', ' ', ' ', 'X', ' ', ' '
            db ' ', ' ', ' ', ' ', 'O', ' ', ' '
            db ' ', ' ', 'O', ' ', ' ', ' ', ' '

    icono_esq_vacia db "   ",0
    salto_linea db 10,0

    ; sequencias ANSI
    ansi_label_celda db 0x1b,"[38;5;033;00000049m %c ",0x1b,"[0m",0
    ansi_celda_seleccionada db 0x1b,"[38;5;000;48;5;033m %c ",0x1b,"[0m",0
    ansi_limpiar_linea db 0x1b,"[%i;0H",0x1b,"[K",0
    ansi_guardar_pos_cursor db 0x1b,"[s",0
    ansi_restaurar_pos_cursor db 0x1b,"[u",0

    ; constantes lectura de archivo
    path_archivo_tablero db "./static/tablero-abajo.dat",0
    modo_lectura_archivo_tablero db "rb",0

    section .bss

    buffer_ansi_celda resb LONGITUD_CELDA_ASCII ; almacena la sequencia ANSI leída del archivo por cada celda
    file_desc_archivo_tablero resq 1 ; file descriptor archivo tablero

    section .text

    ; carga el archivo del tablero correspondiente a la posicion de la fortaleza. no
    ; lee el archivo, pues esto se hace directo en el loop de renderizacion.
    ;
tablero_inicializar:
    mov rdi, path_archivo_tablero
    mov rsi, modo_lectura_archivo_tablero
    call fopen
    mov [file_desc_archivo_tablero], rax
    ret

    ; renderiza el tablero de acuerdo al estado actual del mismo (los valores de la
    ; variable tablero).
    ;
    ; parámetros:
    ; - rdi: 1 si se desean mostrar como seleccionadas las celdas de los movimientos
    ;   posibles de una ficha, 0 en otro caso. para la primera renderización de cada
    ;   turno, antes de que el jugador elija que ficha mover, esto debe valer 0.
    ;
tablero_renderizar:
    push r12
    push r13
    push r14
    push r15

    mov r15, rdi

    ; agregamos el espacio para la esquina de la fila y columna donde se
    ; muestran las labels de las casillas.
    ;
    mov rdi, icono_esq_vacia
    call printf

    ; la primera fila es la fila donde están las labels de las columnas, así que
    ; primero renderizamos solamente esa fila.
    mov r12, 0

    .loop_label_columnas:
    mov r13, r12
    add r13, "A"
    mov rdi, ansi_label_celda
    mov rsi, r13
    call printf

    inc r12
    cmp r12, CANTIDAD_COLUMNAS
    jl .loop_label_columnas

    .continue_label_columnas:
    mov rdi, salto_linea
    call printf

    .loop_renderizacion:
    mov r12, 0 ; índice filas

    .loop_filas:
    mov r13, 0 ; índice columnas

    .loop_columnas:
    ; se lee de archivo de a LONGITUD_CELDA_ASCII bytes, que es la longitud que
    ; tiene la format string de cada celda (con las secuencias de escape ANSI
    ; para darle color).
    ;
    mov rdi, buffer_ansi_celda
    mov rsi, LONGITUD_CELDA_ASCII
    mov rdx, 1
    mov rcx, [file_desc_archivo_tablero]
    call fread

    cmp rax, 0 ; si no hay nada que leer
    je .finalizar

    ; si estamos en la primera columna, tenemos que renderizar el label de la
    ; fila. caso contrario (si r13 > 0) simplemente renderizamos la celda.
    ;
    cmp r13, 0
    jne .continue_renderizar_celda

    .continue_renderizar_label_fila:
    mov r14, r12
    add r14, "0"
    inc r14

    mov rdi, ansi_label_celda
    mov rsi, r14
    call printf

    .continue_renderizar_celda:
    mov r14, r12
    imul r14, CANTIDAD_COLUMNAS
    add r14, r13 ; índice celda actual

    movzx rsi, byte [tablero + r14] ; cargamos el ícono para el printf

    cmp r15, 0 ; no se renderizan celdas como seleccionadas
    je .continue_celda_no_seleccionada

    ; buscamos la posición absoluta de la celda actual en el arreglo de de
    ; movimientos posibles. no es lo más eficiente, porque se está haciendo por
    ; cada celda, pero anda.
    ;
    xor rcx, rcx

    .loop_celda_seleccionada:
    mov al, byte [array_movimientos_posibles + rcx] ; cargo el índice del arreglo de movimientos
    test al, al ; llegué al final del arreglo de movimientos
    jz .continue_celda_no_seleccionada

    cmp al, r14b ; r14 tienen el byte de la posición absoluta actual
    je .continue_celda_seleccionada

    inc rcx
    jmp .loop_celda_seleccionada

    .continue_celda_seleccionada:
    mov rdi, ansi_celda_seleccionada
    jmp .renderizar_celda

    .continue_celda_no_seleccionada:
    mov rdi, buffer_ansi_celda

    .renderizar_celda:
    ; acabo de cargar rdi y recordemos que rsi lo cargue en
    ; .continue_renderizar_celda
    ;
    call printf

    inc r13
    cmp r13, CANTIDAD_COLUMNAS
    jl .loop_columnas ; siguiente columna

    mov rdi, salto_linea
    call printf

    inc r12
    cmp r12, CANTIDAD_COLUMNAS
    jl .loop_filas ; siguiente fila

    .finalizar:
    ; Para poder volver a ocupar el mismo file descriptor en la siguiente
    ; renderización.
    mov rdi, [file_desc_archivo_tablero]
    call rewind

    pop r12
    pop r13
    pop r14
    pop r15

    ret

    ; cierra el archivo del tablero correspondiente a la posicion de la fortaleza
    ;
tablero_finalizar:
    mov rdi, [file_desc_archivo_tablero]
    call fclose
    ret

    ; descripción:
    ; vuelve a renderizar el tablero afectando únicamente el área donde está el
    ; tablero (los primeras líneas de la pantalla).
    ;
    ; parámetros:
    ;  - rdi: se lo pasa a `tablero_renderizar`
    ;
tablero_actualizar:
    push rdi
    sub rsp, 8

    mov rdi, ansi_guardar_pos_cursor
    call printf

    mov r8, 1 ; las líneas arrancan en 1

    .loop_limpiar_linea:
    mov rdi, ansi_limpiar_linea
    mov rsi, r8
    call printf

    inc r8
    cmp r8, 9 ; consideramos la fila de las labels
    jl .loop_limpiar_linea

    add rsp, 8

    pop rdi
    sub rsp, 8
    call tablero_renderizar
    add rsp, 8


    mov rdi, ansi_restaurar_pos_cursor
    call printf

    ret
