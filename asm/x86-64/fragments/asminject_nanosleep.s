// BEGIN: asminject_nanosleep
// basic wrapper around the Linux nanosleep syscall
// rsi = number of seconds to sleep
// rdi = number of nanoseconds to sleep

asminject_nanosleep:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	
	push rsi
	push rdi
	
	mov rdi, rsp	# pointer to the two values just pushed onto the stack
	
	// call sys_nanosleep
	mov rax, 35
	syscall
	
	pop rdi
	pop rsi
	
	leave
	ret

// END: asminject_nanosleep
