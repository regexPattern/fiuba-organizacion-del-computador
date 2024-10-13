	extern procedimiento

	section .text
	global main
main:
	call procedimiento
exit:
	mov rax,60
	mov rdi,0
	syscall
