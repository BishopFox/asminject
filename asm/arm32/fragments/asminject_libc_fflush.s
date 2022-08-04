// BEGIN: asminject_libc_fflush
// wrapper for the libc fflush function
// tested with libc 
// Assumes the signature for fflush is int fflush(FILE * stream);
// if your libc has a different signature for fflush, this code will probably fail
// r0 = file handle

asminject_libc_fflush:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}

// store the address of libc fflush in r10
	ldr r10, [pc]
	b asminject_libc_fflush_call_fflush

asminject_libc_fflush_address:
	.word [SYMBOL_ADDRESS:^fflush($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4
	
asminject_libc_fflush_call_fflush:
	// r0 will already be set to the handle
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r10
	[INLINE:stack_align-r8-r9-post.s:INLINE]

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fflush