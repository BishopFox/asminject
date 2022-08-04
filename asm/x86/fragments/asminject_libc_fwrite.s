// BEGIN: asminject_libc_fwrite
// wrapper for the libc fwrite function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fwrite is size_t fwrite([const] void * ptr, size_t size, size_t count, FILE * stream);
// if your libc has a different signature for fwrite, this code will probably fail
// edi = pointer to buffer
// esi = element size
// eax = number of elements
// ebx = destination file handle
// eax will contain the number of bytes written when this function returns

// the 32-bit x86 version of calling fwrite is handled like this:
// push the arguments to the stack in reverse order:
// * pointer to file descriptor
// * number of elements
// * element size
// * pointer to read buffer
// Call the fwrite function
// add 0x10 to the stack pointer

asminject_libc_fwrite:
	push ebp
	mov ebp, esp	
	sub esp, 0x10
	push edx
	
	[INLINE:stack_align-ecx-edx-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 0, so no extra adjustment necessary
	
	push ebx
	push eax
	push esi
	push edi

	mov edx, [SYMBOL_ADDRESS:^fwrite($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx

	// pop four arguments off of stack:
	add esp, 0x10
	[INLINE:stack_align-ecx-edx-post.s:INLINE]

	pop edx
	leave
	ret

// END: asminject_libc_fwrite