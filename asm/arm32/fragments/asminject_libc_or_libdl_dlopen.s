// BEGIN: asminject_libc_or_libdl_dlopen
// wrapper for the libc/libdl dlopen function
// tested with libdl
// Assumes the signature for dlopen is void *dlopen([const] char *filename, int flags);
// if your libdl has a different signature for dlopen, this code will probably fail
// r0 = string containing .so file path
// r1 = mode value

asminject_libc_or_libdl_dlopen:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}
	
// store the address of dlopen in r10
	ldr r10, [pc]
	b asminject_libc_or_libdl_dlopen_call_inner

asminject_libdl_dlopen_address:
	.word [SYMBOL_ADDRESS:^dlopen($|@@.+):IN_BINARY:.+/lib(dl|c)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4

asminject_libc_or_libdl_dlopen_call_inner:
	// r0 will already be set to the handle
	// r1 will already be set to the mode
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r10
	[INLINE:stack_align-r8-r9-post.s:INLINE]

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_or_libdl_dlopen