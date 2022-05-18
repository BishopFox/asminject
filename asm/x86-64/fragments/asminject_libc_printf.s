// BEGIN: asminject_libc_printf
// simple wrapper for the libc printf function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for printf is int printf([const] char * format, ... );
// if your libc has a different signature for printf, this code will probably fail
// r0 = format string
// r1 = first argument to include in the formatted string

asminject_libc_printf:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}
	push {r9}

// store the base address of libc in r10
asminject_libc_printf_load_base_address:
	ldr r10, [pc]
	b asminject_libc_printf_load_printf_offset

asminject_libc_printf_base_address:
	.word [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS]
	.balign 4
	
// Store the relative offset of printf in r9
asminject_libc_printf_load_printf_offset:
	ldr r9, [pc]
	b asminject_libc_printf_call_printf

asminject_libc_printf_printf_offset:
	.word [RELATIVEOFFSET:printf@@GLIBC.+:RELATIVEOFFSET]
	.balign 4

asminject_libc_printf_call_printf:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0, r1, and so on will already be set by the caller
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_printf