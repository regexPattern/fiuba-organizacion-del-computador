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
extern fflush

%define LONGITUD_CELDA_ASCII 29

section .data
ICONO_ESQ_VACIA db "   ",0
SALTO_LINEA     db 10,0

ANSI_LABEL_CELDA        db 0x1b,"[38;5;033;00000049m %c ",0x1b,"[0m",0
ANSI_CELDA_SELECCIONADA db 0x1b,"[38;5;000;48;5;033m %c ",0x1b,"[0m",0

PATH_ARCHIVO_TABLERO         db "./static/tablero-abajo.dat",0
MODO_LECTURA_ARCHIVO_TABLERO db "rb",0

INPUT_SELEC_FILA  db "seleccionar fila: ",0
INPUT_SELEC_COLUM db "seleccionar columna: ",0
INPUT_ENTERO db "%i",0
INPUT_CHAR   db " %c\n",0

fila_seleccionada    db -1
columna_seleccionada db -1

section .bss
tablero resq 1

buffer_ansi_celda resb LONGITUD_CELDA_ASCII
file_desc_archivo_tablero resq 1

buffer_input_entero resd 1
buffer_input_char   resb 1

section .text

; Básicamente los colores de las celda del tablero están grabados en archivo
; binario que contiene las secuencias de escape ANSI. Así que lo primero es
; abrir el archivo. La lectura del mismo se va hacer directamente en el loop de
; renderización.
tablero_inicializar:
	mov rdi,PATH_ARCHIVO_TABLERO
	mov rsi,MODO_LECTURA_ARCHIVO_TABLERO
	call fopen
	mov [file_desc_archivo_tablero],rax
	ret

; Renderiza el tablero. No retorna nada.
; Parámetros:
;  • rdi - Puntero al tablero
tablero_renderizar:
    mov r15,rdi

	mov r12,0

	; Para la esquina de la fila y columna donde se muestran las labels de las
	; casillas.
	mov rdi,ICONO_ESQ_VACIA
	call printf

	; La primera fila es la fila donde están las labels de las columnas, así que
	; primero renderizamos solamente esa fila.
.loop_label_columnas:
	mov r13,r12
	add r13,"A"
	mov rdi,ANSI_LABEL_CELDA
	mov rsi,r13
	call printf

	inc r12
	cmp r12,7
	jl .loop_label_columnas

	mov rdi,SALTO_LINEA
	call printf

	mov r12,0

	; Loop de renderización principal
.loop_filas:
	mov r13,0

.loop_columnas:
	; Se lee de archivo de a 29 bytes, que es la longitud que tiene la format
	; string de cada celda (con las secuencias de escape ANSI para darle color a
	; su ícono).
	mov rdi,buffer_ansi_celda
	mov rsi,LONGITUD_CELDA_ASCII
	mov rdx,1
	mov rcx,[file_desc_archivo_tablero]
	call fread

	; Si no hay nada que leer
	cmp rax,0
	je .continue_fin_archivo

	; Si estamos en la primera columna, tenemos que renderizar el label de la
	; fila. Caso contrario (si r13 > 0) simplemente renderizamos la celda.
	cmp r13,0
	jne .continue_renderizar_celda

	mov r14,r12
	add r14,"0"
	inc r14

	mov rdi,ANSI_LABEL_CELDA
	mov rsi,r14
	call printf

.continue_renderizar_celda:
	mov r14,r12
	imul r14,7

	; r13 = fila
	; r14 = columna
	add r14,r13
	movzx rsi,byte [r15 + r14]

	; Si estamos renderizando la celda cuyas coordenadas fueron seleccionadas,
	; entonces renderizamos usando el placeholder `ANSI_CELDA_SELECCIONADA`, de
	; lo contrario, renderizamos directamente los bytes que leímos del archivo
	; antes.
	cmp r12b,byte [fila_seleccionada]
	jne .celda_no_seleccionada
	cmp r13b,byte [columna_seleccionada]
	jne .celda_no_seleccionada

	mov rdi,ANSI_CELDA_SELECCIONADA

.celda_no_seleccionada:
	mov rdi,buffer_ansi_celda

.renderizar_celda:
	call printf

	inc r13
	cmp r13,7
	jl .loop_columnas ; siguiente columna

	mov rdi,SALTO_LINEA
	call printf

	inc r12
	cmp r12,7
	jl .loop_filas ; siguiente fila

.continue_fin_archivo:
    ; Para poder volver a ocupar el mismo file descriptor en la siguiente
	; renderización.
	mov rdi,[file_desc_archivo_tablero]
	call rewind

	ret

tablero_seleccionar_celda:
	mov rdi,INPUT_SELEC_FILA
	call printf

	mov rdi,INPUT_ENTERO
	mov rsi,buffer_input_entero
	call scanf

	mov r12d,[buffer_input_entero]

	mov rdi,INPUT_SELEC_COLUM
	call printf

	mov rdi,INPUT_CHAR
	mov rsi,buffer_input_char
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
