	section .text
	global main
main:
exit:
	mov rax,60
	mov rdi,0
	syscall
