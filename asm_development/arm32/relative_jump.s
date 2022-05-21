// test payload to try out relative jumping
// gcc -x assembler -o relative_jump -nostdlib -fPIC -Wl,--build-id=none -s relative_jump.s

.globl _start
_start:

b printf_main

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
	.word 0xb6cd6000
	.balign 4
	
// Store the relative offset of printf in r9
asminject_libc_printf_load_printf_offset:
	ldr r9, [pc]
	b asminject_libc_printf_call_printf

asminject_libc_printf_printf_offset:
	.word 0x00048430
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

printf_main:
	mov r0, pc
	b load_debug_message

format_string:
	.ascii "DEBUG: '%s'\n\0"
	.balign 4

load_debug_message:
	mov r1, pc
	b call_printf

debug_message:
	.ascii "test123\0"
	.balign 4

call_printf:
	push {r0}
	push {r1}
	bl asminject_libc_printf
	pop {r1}
	pop {r0}
// if the relative jump succeeds, the message will only be printed one more time
// if it fails, the message will be printed multiple times, not at all, or the program will crash/hang
// relative jump ahead 0x18
	add pc, pc, #0xFC
// 0x0 offset
	push {r0}
	push {r1}
	bl asminject_libc_printf
	pop {r1}
	pop {r0}
// 0x14 offset - dummy operation for padding
	add r2, r2, #0x0
// 0x18 offset
	push {r0}
	push {r1}
	bl asminject_libc_printf
	pop {r1}
	pop {r0}

