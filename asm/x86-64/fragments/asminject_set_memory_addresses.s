// BEGIN: asminject_set_memory_addresses
// set a payload state value
// rsi = communications address
// rdi = read/execute base address
// rcx = read/write base address

asminject_set_memory_addresses:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	
	// communications address
	push rax
	
	mov rax, rsi
	add rax, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_EXECUTE_BASE_ADDRESS:VARIABLE]
	mov [rax], rdi
	
	mov rax, rsi
	add rax, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_WRITE_BASE_ADDRESS:VARIABLE]
	mov [rax], rcx
	
	pop rax
	
	leave
	ret
	
// END: asminject_set_memory_addresses
