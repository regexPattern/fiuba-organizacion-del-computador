    global ansi_celda_seleccionada
    global buffer_posicion_fortaleza
    global ptr_path_archivo_tablero
    global tablero
    global tablero_actualizar
    global tablero_finalizar
    global tablero_inicializar
    global tablero_renderizar
    global tablero_rotar_90

    extern fclose
    extern fopen
    extern fread
    extern printf
    extern rewind
    extern scanf
    extern buffer_simbolo_oficiales
    extern buffer_simbolo_soldados
    extern setlocale
    extern pos_oficial_1
    extern pos_oficial_2

    extern array_movimientos_posibles

    %define CANTIDAD_COLUMNAS 7
    %define CANTIDAD_ELEMENTOS 49
    %define LONGITUD_CELDA_ASCII 30

    %macro MENSAJE_RESALTADO 1
    db 10,0x1b,"[38;5;231;48;5;9m",%1,0x1b,"[0m",10,0
    %endmacro

    section .data

    buffer_posicion_fortaleza db "^" ; posicion por defecto: abajo

    tablero_arr db ' ', ' ', ' ', ' ', 'O', ' ', ' '
                db ' ', ' ', 'O', ' ', ' ', ' ', ' '
                db 'X', 'X', ' ', ' ', ' ', 'X', 'X'
                db 'X', 'X', 'X', 'X', 'X', 'X', 'X'
                db 'X', 'X', 'X', 'X', 'X', 'X', 'X'
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '

    tablero_der db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db 'X', 'X', 'X', 'X', ' ', 'O', ' '
                db 'X', 'X', 'X', 'X', ' ', ' ', ' '
                db 'X', 'X', 'X', 'X', ' ', ' ', 'O'
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '

    tablero_aba db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db 'X', 'X', 'X', 'X', 'X', 'X', 'X'
                db 'X', 'X', 'X', 'X', 'X', 'X', 'X'
                db 'X', 'X', ' ', ' ', ' ', 'X', 'X'
                db ' ', ' ', ' ', ' ', 'O', ' ', ' '
                db ' ', ' ', 'O', ' ', ' ', ' ', ' '

    tablero_izq db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db 'O', ' ', ' ', 'X', 'X', 'X', 'X'
                db ' ', ' ', ' ', 'X', 'X', 'X', 'X'
                db ' ', 'O', ' ', 'X', 'X', 'X', 'X'
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '
                db ' ', ' ', 'X', 'X', 'X', ' ', ' '

    icono_esq_vacia db "   ",0
    salto_linea db 10,0

    ;                        "♠",   "♥",   "♣",   "♦",   "♩",   "★"
    iconos_oficiales dw "O",0x2660,0x2665,0x2663,0x2666,0x2669,0x2605
    iconos_soldados  dw "X",0x2660,0x2665,0x2663,0x2666,0x2669,0x2605

    ; sequencias ANSI
    ansi_label_celda db 0x1b,"[38;5;033;00000049m %lc ",0x1b,"[0m",0
    ansi_celda_seleccionada db 0x1b,"[38;5;000;48;5;033m %lc ",0x1b,"[0m",0
    ansi_limpiar_linea db 0x1b,"[%i;0H",0x1b,"[K",0
    ansi_guardar_pos_cursor db 0x1b,"[s",0
    ansi_restaurar_pos_cursor db 0x1b,"[u",0

    path_archivo_tablero_aba db "./static/tablero-aba.dat",0
    path_archivo_tablero_arr db "./static/tablero-arr.dat",0
    path_archivo_tablero_der db "./static/tablero-der.dat",0
    path_archivo_tablero_izq db "./static/tablero-izq.dat",0
    modo_lectura_archivo_tablero db "rb",0

    locale db "en_US.UTF-8",0

    section .bss

    buffer_ansi_celda resb LONGITUD_CELDA_ASCII ; almacena la sequencia ANSI leída del archivo por cada celda
    file_desc_archivo_tablero resq 1 ; file descriptor archivo tablero
    tablero resb 49 ; Espacio para almacenar el tablero con la orientacion elegida
    ;temp_tablero resb CANTIDAD_ELEMENTOS ; tablero temporal para realizar la rotacion de 90°

    section .text

    ; carga el archivo del tablero correspondiente a la posicion de la fortaleza. no
    ; lee el archivo, pues esto se hace directo en el loop de renderizacion.
    ;
tablero_inicializar:
    lea rdi, [tablero]          ; Dirección de inicio de tablero (destino)
    mov rcx, CANTIDAD_ELEMENTOS ; Número de bytes a copiar (igual para todos los tableros)

    ; el valor que llega ya esta validado
    cmp byte [buffer_posicion_fortaleza], "^"
    je .posicionar_arr

    cmp byte [buffer_posicion_fortaleza], "v"
    je .posicionar_aba

    cmp byte [buffer_posicion_fortaleza], "<"
    je .posicionar_izq

    jmp .posicionar_der

    .posicionar_aba:
    lea rsi, [tablero_aba]          ; Direccion de tablero seleccionado (fuente)
    rep movsb
    mov rdi, path_archivo_tablero_aba ; para colorear la fortaleza abajo
    mov byte [pos_oficial_1], 44 ; posicion inicial del oficial 1 en este layout
    mov byte [pos_oficial_2], 39 ; posicion inicial del oficial 2 en este layout
    jmp .abrir_archivo_tablero

    .posicionar_arr:
    lea rsi, [tablero_arr] ; copio el template de tablero abajo a tablero
    rep movsb
    mov rdi, path_archivo_tablero_arr ; para colorear la fortaleza arriba
    mov byte [pos_oficial_1], 9
    mov byte [pos_oficial_2], 4
    jmp .abrir_archivo_tablero 

    .posicionar_izq:
    lea rsi, [tablero_izq]
    rep movsb
    mov rdi, path_archivo_tablero_izq
    mov byte [pos_oficial_1], 14
    mov byte [pos_oficial_2], 29
    jmp .abrir_archivo_tablero 

    .posicionar_der:
    lea rsi, [tablero_der]
    rep movsb
    mov rdi, path_archivo_tablero_der
    mov byte [pos_oficial_1], 34
    mov byte [pos_oficial_2], 19

    .abrir_archivo_tablero:
    mov rsi, modo_lectura_archivo_tablero
    call fopen
    mov [file_desc_archivo_tablero], rax

    ; habilito la opcion para imprimir caracteres UNICODE UTF-16
    mov rdi, 0
    mov rsi, locale
    call setlocale

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
    ; acabo de cargar rdi y recordemos que rsi lo cargue con 'X' o 'O' (leido directamente desde el array de bytes del tablero)
    .cargar_icono_oficial:
    cmp rsi, "O"
    jne .cargar_icono_soldado

    movzx rbp, byte [buffer_simbolo_oficiales]
    sub rbp, "0"
    imul rbp, 2
    movzx rsi, word [iconos_oficiales + rbp]

    jmp .cargar_icono

    .cargar_icono_soldado:
    cmp rsi, "X"
    jne .cargar_icono

    movzx rbp, byte [buffer_simbolo_soldados]
    sub rbp, "0"
    imul rbp, 2
    movzx rsi, word [iconos_soldados + rbp]

    .cargar_icono:
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

;tablero_rotar_90:
;    lea rsi, [tablero]
;    lea rdi, [temp_tablero]
;    mov rdx, CANTIDAD_ELEMENTOS
;    rep movsb                   ; copio el tablero original a en temp_tablero
;
;
;    xor r9, r9                  ; r9 = índice fila original (i)
;.loop_filas:
;    xor r10, r10                  ; r10 = índice columna original (j)
;.loop_columnas:
;    ; Calcular índice en el tablero rotado
;    mov rax, r10                 ; rax = j (columna original)
;    imul rax, CANTIDAD_COLUMNAS  ; rax = j * CANTIDAD_COLUMNAS (fila rotada)
;    mov rbx, CANTIDAD_COLUMNAS
;    sub rbx, r9                 ; rbx = CANTIDAD_COLUMNAS - i
;    dec rbx                     ; rbx -= 1
;    add rax, rbx                ; rax = índice en el tablero rotado
;
;    ; Calcular índice en el tablero original
;    mov rbx, r9                 ; rbx = i (fila original)
;    imul rbx, CANTIDAD_COLUMNAS ; rbx = i * CANTIDAD_COLUMNAS
;    add rbx, r10                 ; rbx = índice en el tablero original
;
;    ; Mover el valor
;    mov dl, byte [temp_tablero + rbx]
;    mov byte [tablero + rax], dl
;
;    ; Incrementar columna
;    inc r10
;    cmp r10, CANTIDAD_COLUMNAS
;    jl .loop_columnas
;
;    ; Incrementar fila
;    inc r9
;    cmp r9, CANTIDAD_COLUMNAS
;    jl .loop_filas
;
;    ret
