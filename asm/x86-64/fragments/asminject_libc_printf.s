// BEGIN: asminject_libc_printf
// simple wrapper for the libc printf function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for printf is int printf([const] char * format, ... );
// if your libc has a different signature for printf, this code will probably fail
// rdi = format string
// rsi = first argument to include in the formatted string

asminject_libc_printf:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push rcx
	push rdx
	
	mov rcx, 0
	mov rdx, 0
	mov r9, [FUNCTION_ADDRESS:^printf($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	call r9

	pop rdx
	pop rcx
	pop r9
	leave
	ret
// END: asminject_libc_printf