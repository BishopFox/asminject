	// BEGIN: example of calling a LIBC function from the asm code using template values
	push r14
	push rax
	push rbx
	lea rsi, dmsg[rip]
	lea rdi, format_string[rip]
	xor rax, rax
	xor eax, eax
	movabsq rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC.+:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop rax
	pop r14
	// END: example of calling a LIBC function from the asm code using template values
	
	mov rax, 0

SHELLCODE_SECTION_DELIMITER

format_string:
	.ascii "DEBUG: %s\0"

dmsg:
	.ascii "ZYXWVUTSRQPONMLKJIHG\0"

