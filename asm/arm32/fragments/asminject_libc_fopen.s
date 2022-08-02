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

// store the address of libc fopen in r10
	ldr r10, [pc]
	b asminject_libc_fopen_call_fopen

asminject_libc_fopen_address:
	.word [FUNCTION_ADDRESS:^fopen($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	.balign 4

asminject_libc_fopen_call_fopen:
	// r0 will already be set to the path to the file
	// r1 will already be set to the mode string
	blx r10

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fopen