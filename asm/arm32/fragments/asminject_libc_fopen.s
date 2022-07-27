// BEGIN: asminject_libc_fopen
// wrapper for the libc fopen function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fopen is FILE * fopen([const] char * filename, [const] char * mode);
// if your libc has a different signature for fopen, this code will probably fail
// r0 = path to file
// r1 = mode string ("r\0", "w\0", etc.)
// r0 will contain the handle when this function returns

asminject_libc_fopen:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}
	push {r9}

// store the base address of libc in r10
	ldr r10, [pc]
	b asminject_libc_fopen_load_fopen_offset

asminject_libc_fopen_base_address:
	.word [BASEADDRESS:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	.balign 4
	
// Store the relative offset of fopen in r9
asminject_libc_fopen_load_fopen_offset:
	ldr r9, [pc]
	b asminject_libc_fopen_call_fopen

asminject_libc_fopen_fopen_offset:
	.word [RELATIVEOFFSET:^fopen($|@@.+):RELATIVEOFFSET]
	.balign 4

asminject_libc_fopen_call_fopen:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0 will already be set to the path to the file
	// r1 will already be set to the mode string
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fopen