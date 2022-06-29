// BEGIN: asminject_wait_for_value_at_address
// wait for a particular word to be set at a particular address
// e.g. for checking script communication state variable
// rsi = address to check
// rdi = value to wait for

// import reusable code fragments 
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

asminject_wait_for_value_at_address:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	
	push rdi
	push rsi
	
	// address to check
	push %r0%
	// value to wait for
	push %r1%
	// register to load data at address into
	push %r2%
	
	mov %r0%, rsi
	mov %r1%, rdi

asminject_wait_for_value_at_address_wait_loop:
	mov %r2%, [%r0%]
	cmp %r2%, %r1%
	je asminject_wait_for_value_at_address_done_looping

	// rsi = number of seconds to sleep
	// rdi = number of nanoseconds to sleep
	mov rsi, 1
	mov rdi, 1
	push %r0%
	push %r1%
	push %r2%
	call asminject_nanosleep
	pop %r2%
	pop %r1%
	pop %r0%

	jmp asminject_wait_for_value_at_address_wait_loop
	
asminject_wait_for_value_at_address_done_looping:	
	
	pop %r2%
	pop %r1%
	pop %r0%

	pop rsi
	pop rdi
	
	leave
	ret
	
// END: asminject_wait_for_value_at_address
