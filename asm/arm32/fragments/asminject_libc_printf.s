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

// store the base address of libc in r10
asminject_libc_printf_load_base_address:
	ldr r10, [pc]
	b asminject_libc_printf_call_printf

asminject_libc_printf_address:
	.word [SYMBOL_ADDRESS:^printf($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4

asminject_libc_printf_call_printf:
	// r0, r1, and so on will already be set by the caller
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r10
	[INLINE:stack_align-r8-r9-post.s:INLINE]

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libc_printf