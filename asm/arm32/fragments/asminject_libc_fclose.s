// BEGIN: asminject_libc_fclose
// wrapper for the libc fclose function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fclose is int fclose(FILE * stream);
// if your libc has a different signature for fclose, this code will probably fail
// r0 = file handle

asminject_libc_fclose:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}

// store the address of libc fclose in r10
	ldr r10, [pc]
	b asminject_libc_fclose_call_fclose

asminject_libc_fclose_address:
	.word [SYMBOL_ADDRESS:^fclose($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4
	
asminject_libc_fclose_call_fclose:
	// r0 will already be set to the handle
	blx r10

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fclose