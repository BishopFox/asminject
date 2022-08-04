// BEGIN: asminject_libc_fclose
// wrapper for the libc fclose function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fclose is int fclose(FILE * stream);
// if your libc has a different signature for fclose, this code will probably fail
// rdi = file handle

asminject_libc_fclose:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push r14
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	mov r9, [SYMBOL_ADDRESS:^fclose($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9

	[INLINE:stack_align-r8-post.s:INLINE]

	pop r14
	pop r9
	leave
	ret
	
// END: asminject_libc_fclose