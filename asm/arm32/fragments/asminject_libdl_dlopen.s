// BEGIN: asminject_libdl_dlopen
// wrapper for the libdl dlopen function
// tested with libdl 2.28 and 2.33
// Assumes the signature for dlopen is void *dlopen([const] char *filename, int flags);
// if your libdl has a different signature for dlopen, this code will probably fail
// r0 = string containing .so file path

asminject_libdl_dlopen:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}
	push {r9}

// store the base address of libdl in r10
	ldr r10, [pc]
	b asminject_libdl_dlopen_load_dlopen_offset

asminject_libdl_dlopen_base_address:
	.word [BASEADDRESS:.+/libdl-[0-9\.]+.so$:BASEADDRESS]
	.balign 4
	
// Store the relative offset of dlopen in r9
asminject_libdl_dlopen_load_dlopen_offset:
	ldr r9, [pc]
	b asminject_libdl_dlopen_call_dlopen

asminject_libdl_dlopen_dlopen_offset:
	.word [RELATIVEOFFSET:^dlopen($|@@.+):RELATIVEOFFSET]
	.balign 4

asminject_libdl_dlopen_call_dlopen:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0 will already be set to the handle
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libdl_dlopen