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
	push {r9}
	push {r8}
	
	// ensure the stack is 16-byte aligned, because some versions of libpthread are super picky about this
asminject_libc_or_libdl_dlopen_align_stack:
	mov r8, sp
	sub r8, r8, #0x4	// one more register will be pushed onto the stack after this check
	and r9, r8, #0x8
	cmp r9, #8
	bne asminject_libc_or_libdl_dlopen_push_one
	push {r8}
	push {r8}
	asminject_libc_or_libdl_dlopen_push_one:
	and r9, r8, #0x4
	cmp r9, #4
	bne asminject_libc_or_libdl_dlopen_load_address
	push {r8}

asminject_libc_or_libdl_dlopen_load_address:
	push {r8}
	
// store the address of dlopen in r10
	ldr r10, [pc]
	b asminject_libc_or_libdl_dlopen_call_inner

asminject_libdl_dlopen_address:
	.word [SYMBOL_ADDRESS:^dlopen($|@@.+):IN_BINARY:.+/lib(dl|c)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4

asminject_libc_or_libdl_dlopen_call_inner:
	// r0 will already be set to the handle
	// r1 will already be set to the mode
	blx r10

	pop {r8}
	
// remove extra values from the stack if any were added to align it

	and r9, r8, #0x8
	cmp r9, #8
	bne asminject_libc_or_libdl_dlopen_pop_one
	pop {r8}
	pop {r8}
asminject_libc_or_libdl_dlopen_pop_one:
	and r9, r8, #0x4
	cmp r9, #4
	bne asminject_libc_or_libdl_dlopen_cleanup
	pop {r8}

asminject_libc_or_libdl_dlopen_cleanup:
	pop {r8}
	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_or_libdl_dlopen