// BEGIN: asminject_wait_for_script_state
// wait for the script to set a particular state value
// rsi = communications address
// rdi = value to wait for

// import reusable code fragments 
[FRAGMENT:asminject_wait_for_value_at_address.s:FRAGMENT]

asminject_wait_for_script_state:
	push rbp
	mov rbp, rsp
	sub rsp, 0x20
	
	push rsi
	push rdi
	
	add rsi, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_STATE:VARIABLE]

	call asminject_wait_for_value_at_address
	
	pop rdi	
	pop rsi
	
	leave
	ret
	
// END: asminject_wait_for_script_state
