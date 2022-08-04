// BEGIN: asminject_libc_fread
// wrapper for the libc fread function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fread is size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );
// if your libc has a different signature for fread, this code will probably fail
// r0 = pointer to buffer
// r1 = element size
// r2 = number of elements
// r3 = source file handle
// r0 will contain the number of bytes read when this function returns

asminject_libc_fread:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}

// store the address of libc fread in r10
	ldr r10, [pc]
	b asminject_libc_fread_call_fread

asminject_libc_fread_address:
	.word [SYMBOL_ADDRESS:^fread($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4

asminject_libc_fread_call_fread:
	// r0-r3 will already be set to the necessary arguments
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r10
	[INLINE:stack_align-r8-r9-post.s:INLINE]

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fread