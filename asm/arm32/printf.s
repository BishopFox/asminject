// test payload to call printf() from libc
	mov r0, pc
	b load_debug_message

format_string:
	.ascii "DEBUG: '%s'\n\0"
	.balign 4

load_debug_message:
	mov r1, pc
	b load_base_address

debug_message:
	.ascii "[VARIABLE:message:VARIABLE]\0"
	.balign 4

load_base_address:
	ldr r9, [pc]
	b load_printf_offset

base_address:
	.word [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS]
	.balign 4

load_printf_offset:
	ldr r8, [pc]
	b call_printf

printf_offset:
	.word [RELATIVEOFFSET:printf@@GLIBC_2.4:RELATIVEOFFSET]
	.balign 4

call_printf:
	add r9, r9, r8
	blx r9
SHELLCODE_SECTION_DELIMITER
