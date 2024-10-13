	extern printf

	section .data
string: db "asalto",10,0

	section .text
	global procedimiento
procedimiento:
	mov rdi,string
	call printf
	ret
