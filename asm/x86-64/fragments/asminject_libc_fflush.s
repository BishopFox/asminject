// BEGIN: asminject_libc_fflush
// wrapper for the libc fflush function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fflush is size_t fflush(FILE * stream);
// if your libc has a different signature for fflush, this code will probably fail
// rdi = file handle
asminject_libc_fflush:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push r14
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	mov r9, [SYMBOL_ADDRESS:^fflush($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9
	
	[INLINE:stack_align-r8-post.s:INLINE]

	pop r14
	pop r9
	leave
	ret
// END: asminject_libc_fflush