// BEGIN: asminject_set_payload_state
// set a payload state value
// rsi = communications address
// rdi = value to set

asminject_set_payload_state:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	
	// communications address
	push %r0%
	// value to set
	push %r1%
	
	mov %r0%, rsi
	add %r0%, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_STATE:VARIABLE]
	mov [%r0%], rdi
	
	pop %r1%
	pop %r0%
	
	leave
	ret
	
// END: asminject_set_payload_state
