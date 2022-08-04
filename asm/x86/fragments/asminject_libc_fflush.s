// BEGIN: asminject_libc_fflush
// wrapper for the libc fflush function
// tested with libc 
// Assumes the signature for fflush is int fflush(FILE * stream);
// if your libc has a different signature for fflush, this code will probably fail
// edi = file handle

// the 32-bit x86 version of calling fflush is handled like this:
// subtract 0xc from the stack pointer
// push the argument to the stack:
// * pointer to file descriptor
// Call the fflush function
// add 0x10 to the stack pointer

asminject_libc_fflush:
	push ebp
	mov ebp, esp	
	sub esp, 0x10
	push edx
	
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 1, so subtract 0xc
	sub esp, 0xc
	
	push edi

	mov edx, [SYMBOL_ADDRESS:^fflush($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx

	// pop one argument + alignment placeholder off of stack:
	add esp, 0x10
	[INLINE:stack_align-ebx-eax-post.s:INLINE]

	pop edx
	leave
	ret
	
// END: asminject_libc_fflush