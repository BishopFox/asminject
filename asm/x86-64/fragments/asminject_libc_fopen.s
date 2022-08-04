// BEGIN: asminject_libc_fopen
// wrapper for the libc fopen function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fopen is FILE * fopen([const] char * filename, [const] char * mode);
// if your libc has a different signature for fopen, this code will probably fail
// rdi = path to file
// rsi = mode string ("r\0", "w\0", etc.)
// rax will contain the handle when this function returns

asminject_libc_fopen:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push r14
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	mov r9, [SYMBOL_ADDRESS:^fopen($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9

	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop r14
	pop r9
	leave
	ret

// END: asminject_libc_fopen