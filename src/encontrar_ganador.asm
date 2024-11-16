global encontrar_ganador
extern printf
section .data
formatoFila db "%s", 0 ; Formato para cada fila
mensaje     db "soldado: ",10,0
mensajeDos  db "oficial: ",10,0
mensajeTres db "Lo que hay en la posicion es: %c",10,0
CANT_FIL	dq	7
CANT_COL	dq	7
LONG_ELEM   dq  1
indice dq	27

section .text

; Retorna en RAX al ganador (si lo hay).
; 0 Si no hay.
; 1 Si ganaron los soldados.
; 2 Si ganaron los oficiales.
; Parametros:
;  • rdi - Turno actual(0 = oficiales y 1 = soldados)
;  • rsi - Puntero al tablero
encontrar_ganador:
    mov     r13, rsi ; r13 = puntero al tablero
    mov     r8, rdi ; r8 = turno actual
    xor     r9, r9 ; r9 = ganador
    
    ; Descomentar las siguientes 2 lineas para devolver que 
    ; aun no hay ganador y no probar la logica de este modulo!!!
    ;mov rax, r9
    ;ret

    cmp     r8, 0
    je      .comprobar_fortaleza_ocupada
    cmp     r8, 1
    je      .chequear_si_ganan_oficiales

; Retorna "1" si:
; 1) Todas las posiciones de la fortaleza estan ocupadas
; Si no, comprueba si los oficiales pueden moverse
.comprobar_fortaleza_ocupada:
    mov		rcx,[indice]
    dec		rcx
    imul	rbx,rcx,1
    mov		rax,[rsi+rbx]
    mov     rsi, rax
    mov     rdi, mensajeTres
    call    printf

    jmp .comprobar_oficiales_incapacitados

.comprobar_oficiales_incapacitados:
    mov     rax, 0
    ret
.ganaron_soldados:
    inc     r9
    mov     rax, r9
    ret

; Retorna "2" si:
; 1) Solo queden 8 soldados(o menos)
.chequear_si_ganan_oficiales:
    mov     rax, 0
    ret

.ganaron_oficiales:
    inc     r9
    inc     r9
    mov     rax, r9
    ret
