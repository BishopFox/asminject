[FRAGMENT:asminject_libc_printf.s:FRAGMENT]

	push ecx
	push edx
	// BEGIN: example of calling a LIBC function from the asm code using template values
	//lea edi, format_string[eip]
	// lea edi, format_string
	# set EDI to the address of the format string
	call printf_format_string_get_next
printf_format_string_get_next:
	pop edi
	add edi, 6
	jmp printf_format_string_step_2

format_string:
	.ascii "[VARIABLE:formatstring:VARIABLE]\n\0"

printf_format_string_step_2:
	
	//lea esi, dmsg[eip]
	//lea esi, dmsg
# set ESI to the address of the message string
	call printf_dmsg_get_next
printf_dmsg_get_next:
	pop esi
	add esi, 6
	jmp printf_format_string_step_3

dmsg:
	.ascii "[VARIABLE:message:VARIABLE]\0"

printf_format_string_step_3:
	call asminject_libc_printf
	// END: example of calling a LIBC function from the asm code using template values
	pop edx
	pop ecx

SHELLCODE_SECTION_DELIMITER





