global tablero
global tablero_finalizar
global tablero_inicializar
global tablero_renderizar
global tablero_seleccionar_celda

extern fclose
extern fopen
extern fread
extern printf
extern rewind
extern scanf

%define LONGITUD_CELDA_ASCII 29

section .data

tablero db ' ', ' ', ' ', ' ', ' ', ' ', ' '
        db ' ', ' ', ' ', ' ', ' ', ' ', ' '
        db ' ', ' ', ' ', ' ', ' ', ' ', ' '
        db ' ', ' ', ' ', ' ', ' ', 'X', ' '
        db ' ', ' ', ' ', ' ', ' ', 'O', ' '
        db ' ', ' ', ' ', ' ', ' ', ' ', ' '
        db ' ', ' ', ' ', ' ', ' ', ' ', ' '

icono_esq_vacia db "   ",0
salto_linea db 10,0

; sequencias ANSI
ansi_label_celda db 0x1b,"[38;5;033;00000049m %c ",0x1b,"[0m",0
ansi_celda_seleccionada db 0x1b,"[38;5;000;48;5;033m %c ",0x1b,"[0m",0
ansi_limpiar_pantalla db 0x1b,"[2J",0x1b,"[H",0

; constantes lectura de archivo
path_archivo_tablero db "./static/tablero-abajo.dat",0
modo_lectura_archivo_tablero db "rb",0

; constantes scanf
input_selec_fila db "seleccionar fila: ",0
input_selec_colum db "seleccionar columna: ",0
input_entero db "%i",0
input_char db " %c\n",0

fila_seleccionada db -1
columna_seleccionada db -1

section .bss

buffer_ansi_celda resb LONGITUD_CELDA_ASCII
buffer_input_char resb 1
buffer_input_entero resd 1
file_desc_archivo_tablero resq 1

section .text

; DESCRIPCIÓN:
;  Básicamente los colores de las celda del tablero están grabados en archivo
;  binario que contiene las secuencias de escape ansi. Así que lo primero es
;  abrir el archivo. La lectura del mismo se va hacer directamente en el loop de
;  renderización.
tablero_inicializar:
	mov rdi, path_archivo_tablero
	mov rsi, modo_lectura_archivo_tablero
	call fopen
	mov [file_desc_archivo_tablero],rax
	ret

; DESCRIPCIÓN:
;  limpia la consola e imprime el tablero por pantalla, con las fichas, colores
;  del castillo, índices para indicar filas y columnas y mostrando las celdas que
;  están seleccionadas (por ejemplo, para mover una ficha).
;
; PARÁMETROS:
; * rdi - puntero al arreglo de movimientos posibles absolutos (no los offsets
;   relativos a la ficha a mover, sino que los índices del 0 al 48) o 0, si no se
;   no hay celdas seleccionadas (por ejemplo, al inicio de cada turno).
;
tablero_renderizar:
    push rbp
    push r12
    push r13
    push r14

    mov rbp, rdi

    ; limpiamos la pantalla en cada render
    ; mov rdi, ansi_limpiar_pantalla
    ; call printf

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
	cmp r12,7
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
	add r14,"0"
	inc r14

	mov rdi, ansi_label_celda
	mov rsi, r14
	call printf

.continue_renderizar_celda:
	mov r14, r12
	imul r14, 7
	add r14, r13 ; posición absoluta celda actual

	movzx rsi,byte [tablero + r14] ; cargamos el ícono para el printf

	; si el puntero pasado es NULL (0), entonces no nos importa renderizar
	; celdas seleccionadas, renderizamos todas como deseleccionadas.
	;
	test rbp, rbp
	jz .continue_celda_no_seleccionada

	; buscamos la posición absoluta de la celda actual en el arreglo de
    ; posiciones absolutas de movimientos posibles. no es lo más eficiente,
    ; porque se está haciendo por cada celda, pero anda.
    ;
    xor rcx, rcx

.loop_celda_seleccionada:
    mov al, byte [rbp + rcx] ; cargo el índice del arreglo de movimientos
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
	call printf

	inc r13
	cmp r13, 7
	jl .loop_columnas ; siguiente columna

	mov rdi, salto_linea
	call printf

	inc r12
	cmp r12, 7
	jl .loop_filas ; siguiente fila

.finalizar:
    ; Para poder volver a ocupar el mismo file descriptor en la siguiente
	; renderización.
	mov rdi, [file_desc_archivo_tablero]
	call rewind

	pop rbp
	pop r12
	pop r13
	pop r14

	ret

tablero_seleccionar_celda:
	mov rdi, input_selec_fila
	call printf

	mov rdi, input_entero
	mov rsi, buffer_input_entero
	call scanf

	mov r12d,[buffer_input_entero]

	mov rdi, input_selec_colum
	call printf

	mov rdi, input_char
	mov rsi, buffer_input_char
	call scanf

	mov r13b,[buffer_input_char]

	sub r12d,1
	sub r13b,"A"

	mov [fila_seleccionada],r12d
	mov [columna_seleccionada],r13b

	ret

tablero_finalizar:
	mov rdi,[file_desc_archivo_tablero]
	call fclose
	ret
