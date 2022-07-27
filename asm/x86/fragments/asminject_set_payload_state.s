// BEGIN: asminject_set_payload_state
// set a payload state value
// esi = communications address
// edi = value to set

asminject_set_payload_state:
	push ebp
	mov ebp, esp
	sub esp, 0x20
	
	// communications address
	push %r0%
	// value to set
	push %r1%
	
	mov %r0%, esi
	add %r0%, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_STATE:VARIABLE]
	mov [%r0%], edi
	
	pop %r1%
	pop %r0%
	
	leave
	ret
	
// END: asminject_set_payload_state
