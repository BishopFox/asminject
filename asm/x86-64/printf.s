[FRAGMENT:asminject_libc_printf.s:FRAGMENT]

	push r14
	// BEGIN: example of calling a LIBC function from the asm code using template values
	lea rdi, format_string[rip]
	lea rsi, dmsg[rip]
	call asminject_libc_printf
	// END: example of calling a LIBC function from the asm code using template values
	pop r14

SHELLCODE_SECTION_DELIMITER

format_string:
	.ascii "[VARIABLE:formatstring:VARIABLE]\n\0"

dmsg:
	.ascii "[VARIABLE:message:VARIABLE]\0"

