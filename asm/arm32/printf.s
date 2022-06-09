// test payload to call printf() from libc
// --var formatstring "DEBUG: '%s'" --var message 'test123'

[FRAGMENT:asminject_libc_printf.s:FRAGMENT]

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
	bl asminject_libc_printf

SHELLCODE_SECTION_DELIMITER
