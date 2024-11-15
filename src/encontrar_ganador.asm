global encontrar_ganador
extern printf
section .data
formatoFila db "%c%c%c%c%c%c%c\n", 0 ; Formato para cada fila
mensaje db "ASDF",10,0

section .text

; Retorna en RAX al ganador (si lo hay).
; 0 Si no hay.
; 1 Si ganaron los soldados.
; 2 Si ganaron los oficiales.
; Parametros:
;  • rdi - Turno actual(0 = oficiales y 1 = soldados)
;  • rsi - Puntero al tablero
encontrar_ganador:
    mov r13, rsi ; r13 = puntero al tablero
    mov r8, rdi ; r8 = turno actual
    xor r9, r9 ; r9 = ganador

    ; Descomentar las siguientes 2 lineas para devolver que 
    ; aun no hay ganador y no probar la logica de este modulo!!!
    ;mov rax, r9
    ;ret

    cmp r8, 1
    je .chequear_si_ganan_soldados
    cmp r8, 0
    ;je .chequear_si_ganan_oficiales
    mov rax, r9
    ret

; Retorna "1" si:
; 1) Todas las posiciones de la fortaleza estan ocupadas
; 2) Los oficiales no pueden moverse.
.chequear_si_ganan_soldados:
    mov rcx, 7 ; Número de filas
    mov rdi, mensaje
    call printf


.ganaron_soldados:
    inc r9
    mov rax, r9
    ret

; Retorna "2" si:
; 1) Solo queden 8 soldados(o menos)
.chequear_si_ganan_oficiales:
    mov rcx, 7 ; Número de filas
    ret

.ganaron_oficiales:
    inc r9
    inc r9
    mov rax, r9
    ret
