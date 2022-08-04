// BEGIN: asminject_nanosleep
// basic wrapper around the Linux nanosleep syscall
// rsi = number of seconds to sleep
// rdi = number of nanoseconds to sleep

asminject_nanosleep:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	
	push rax

	[INLINE:stack_align-r8-pre.s:INLINE]

	// push rsi and rdi onto the stack and then use the resulting stack pointer
	// as the value to pass to sys_nanosleep, to avoid having to refer to an 
	// offset or allocate memory
	push rsi
	push rdi
		
	// pointer to the two values just pushed onto the stack
	mov rdi, rsp
	// clearing rsi is important
	xor rsi, rsi
	
	// call sys_nanosleep
	mov rax, 35
	syscall
	
	pop rdi
	pop rsi
	
	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop rax
	
	leave
	ret

// END: asminject_nanosleep
