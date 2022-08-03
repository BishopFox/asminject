// BEGIN: asminject_libc_fwrite
// wrapper for the libc fwrite function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fwrite is size_t fwrite([const] void * ptr, size_t size, size_t count, FILE * stream);
// if your libc has a different signature for fwrite, this code will probably fail
// rdi = pointer to buffer
// rsi = element size
// rdx = number of elements
// rcx = destination file handle
// rax will contain the number of bytes written when this function returns
asminject_libc_fwrite:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push r14
	
	mov r9, [SYMBOL_ADDRESS:^fwrite($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9

	pop r14
	pop r9
	leave
	ret
// END: asminject_libc_fwrite