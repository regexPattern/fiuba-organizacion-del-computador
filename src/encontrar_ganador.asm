global encontrar_ganador

section .text

; Retorna en RAX al ganador (si lo hay).
; 0 Si no hay.
; 1 Si ganaron los soldados.
; 2 Si ganaron los oficiales.
; Parametros:
;  • rdi - Puntero al tablero
;  • rsi - Turno actual(0 = oficiales y 1 = soldados)
encontrar_ganador:
    mov r8, rsi ; r8 = turno actual
    xor r9, r9 ; r9 = ganador
    cmp r8, 1
    je .chequear_si_ganan_soldados
    cmp r8, 0
    je .chequear_si_ganan_oficiales
    mov rax, r9
    ret

; Retorna "1" si:
; 1) Todas las posiciones de la fortaleza estan ocupadas
; 2) Los oficiales no pueden moverse.
.chequear_si_ganan_soldados:



.ganaron_soldados:
    inc r9
    mov rax, r9
    ret

; Retorna "2" si:
; 1) Solo queden 8 soldados(o menos)
.chequear_si_ganan_oficiales:


.ganaron_oficiales:
    inc r9
    inc r9
    mov rax, r9
    ret
