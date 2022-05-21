// --var formatstring "DEBUG: '%s'" --var message 'test123'

b printf_loop_main
// import reusable code fragments
[FRAGMENT:asminject_libc_printf.s:FRAGMENT]
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

printf_loop_main:


// test payload to call printf() from libc in a loop 10 times with a delay
	mov r6, #10
	mov r5, #0
	mov r0, pc
	b load_debug_message

format_string:
	.ascii "[VARIABLE:formatstring:VARIABLE]\n\0"
	.balign 4

load_debug_message:
	mov r1, pc
	b call_printf

debug_message:
	.ascii "[VARIABLE:message:VARIABLE]\0"
	.balign 4

call_printf:
	// sleep before looping
	push {r0}
	push {r1}
	push {r7}
	push {r8}
	push {r11}
	mov r0, #0x02
	mov r1, #0x02
	bl asminject_nanosleep
	pop {r11}
	pop {r8}
	pop {r7}
	pop {r1}
	pop {r0}

	push {r0}
	push {r1}
	push {r2}
	push {r5}
	push {r6}
	push {r11}
	mov r2, #0x0	@ set last argument to null
	bl asminject_libc_printf
	pop {r11}
	pop {r6}
	pop {r5}
	pop {r2}
	pop {r1}
	pop {r0}

	add r5, r5, #1
	cmp r6, r5
	beq done_looping
	b call_printf

done_looping:
	
SHELLCODE_SECTION_DELIMITER
