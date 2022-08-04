// BEGIN: asminject_libc_fwrite
// wrapper for the libc fwrite function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fwrite is size_t fwrite([const] void * ptr, size_t size, size_t count, FILE * stream);
// if your libc has a different signature for fwrite, this code will probably fail
// r0 = pointer to buffer
// r1 = element size
// r2 = number of elements
// r3 = destination file handle
// r0 will contain the number of bytes written when this function returns

asminject_libc_fwrite:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}

// store the address of libc fwrite in r10
	ldr r10, [pc]
	b asminject_libc_fwrite_call_fwrite

asminject_libc_fwrite_address:
	.word [SYMBOL_ADDRESS:^fwrite($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4

asminject_libc_fwrite_call_fwrite:
	// r0-r3 will already be set to the necessary arguments
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r10
	[INLINE:stack_align-r8-r9-post.s:INLINE]

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fwrite