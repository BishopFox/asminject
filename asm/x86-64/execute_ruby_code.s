[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

	# // BEGIN: call ruby_sysinit
	# push rbx
	# lea rax, ruby_argv[rip]	# fake argv data
	# lea rdx, ruby_argc[rip]	# fake argc data
	# mov rsi, rdx
	# mov rdi, rax
	# mov rbx, [SYMBOL_ADDRESS:^ruby_sysinit$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	# call rbx
	# pop rbx
	# // END: call ruby_sysinit
	
	# // BEGIN: call ruby_init_stack
	# push rbx
	# lea rax, [RBP - 8]
	# mov rdi, rax
	# mov rbx, [SYMBOL_ADDRESS:^ruby_init_stack$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	# call rbx
	# pop rbx
	# // END: call ruby_init_stack
	
	# // BEGIN: call ruby_init
	# push rbx
	# mov rbx, [SYMBOL_ADDRESS:^ruby_init$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	# call rbx
	# pop rbx
	# // END: call ruby_init
	
	# // BEGIN: call ruby_init_loadpath
	# push rbx
	# mov rbx, [SYMBOL_ADDRESS:^ruby_init_loadpath$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	# call rbx
	# pop rbx
	# // END: call ruby_init_loadpath
	
	// copy the Ruby string to arbitrary read/write memory
	push r14
	mov rdi, arbitrary_read_write_data_address[rip]
	lea rsi, ruby_code[rip]
	mov rcx, [VARIABLE:rubycode.length:VARIABLE]
	add rcx, 2												# null terminator
	//call asminject_copy_bytes
	rep movsb
	pop r14
	// END: copy the Ruby string to arbitrary read/write memory
	
	// BEGIN: call rb_eval_string
	push r14
	push rdx
	push rbx
	//mov rdi, arbitrary_read_write_data_address[rip]
	//add rdi, 32
	//xor rsi, rsi
	//lea rdi, ruby_code[rip]
	mov rdi, arbitrary_read_write_data_address[rip]
	xor rsi, rsi
	mov rbx, [SYMBOL_ADDRESS:^rb_eval_string$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	call rbx
	pop rbx
	pop rdx
	pop r14
	// END: call rb_eval_string
	
	# // BEGIN: call ruby_cleanup
	# push rbx
	# mov rdi, 0
	# mov rbx, [SYMBOL_ADDRESS:^ruby_cleanup$:IN_BINARY:.+/libruby[0-9\.so\-]+$:SYMBOL_ADDRESS]
	# call rbx
	# pop rbx
	# // END: call ruby_cleanup
	
	#mov rax, 0

SHELLCODE_SECTION_DELIMITER

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"

#ruby_argv:
#	.ascii "\0"
	
#ruby_argc:
#	.byte 1

