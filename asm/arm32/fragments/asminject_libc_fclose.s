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
	push {r9}

// store the base address of libc in r10
	ldr r10, [pc]
	b asminject_libc_fclose_load_fclose_offset

asminject_libc_fclose_base_address:
	.word [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS]
	.balign 4
	
// Store the relative offset of fclose in r9
asminject_libc_fclose_load_fclose_offset:
	ldr r9, [pc]
	b asminject_libc_fclose_call_fclose

asminject_libc_fclose_fclose_offset:
	.word [RELATIVEOFFSET:^fclose($|@@.+):RELATIVEOFFSET]
	.balign 4

asminject_libc_fclose_call_fclose:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0 will already be set to the handle
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_fclose