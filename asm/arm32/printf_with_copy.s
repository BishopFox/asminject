// test payload to call printf() from libc
// both on a hardcoded value within this payload
// as well as after copying it using the asminject_copy_bytes utility function

b printf_with_copy_main
// import reusable code fragments
[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]
[FRAGMENT:asminject_libc_printf.s:FRAGMENT]

printf_with_copy_main:	
	mov r0, pc
	b load_debug_message

format_string1:
	.ascii "Original string: '%s'\n\0"
	.balign 4

load_debug_message:
	mov r1, pc
	b call_printf

debug_message:
	.ascii "[VARIABLE:message:VARIABLE]\0"
	.balign 4

call_printf:
	push {r1}
	bl asminject_libc_printf
	pop {r1}
	
// copy the string into read/write memory
mov r0, r1		@ Set r0 (source) to address of hardcoded debug message
ldr r1, [pc] 	@ Set r1 (destination) to the read/write memory address
b copy_string

read_write_address:
	.word [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 4

copy_string:
	mov r2, #[VARIABLE:message.length:VARIABLE]
	add r2, r2, #0x1	@ null terminator
	push {r9}
	push {r1}
	push {r0}
	bl asminject_copy_bytes
	pop {r0}
	pop {r1}
	pop {r9}
	#mov r2, #0x0
	#mov r1, r0
	
	mov r0, pc
	b call_printf_again

format_string2:
	.ascii "Copied string: '%s'\n\0"
	.balign 4

call_printf_again:
	bl asminject_libc_printf

SHELLCODE_SECTION_DELIMITER
