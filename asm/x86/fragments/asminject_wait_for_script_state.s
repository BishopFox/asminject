// BEGIN: asminject_wait_for_script_state
// wait for the script to set a particular state value
// esi = communications address
// edi = value to wait for

// import reusable code fragments 
[FRAGMENT:asminject_wait_for_value_at_address.s:FRAGMENT]

asminject_wait_for_script_state:
	push ebp
	mov ebp, esp
	sub esp, 0x20
	
	push esi
	push edi
	
	add esi, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_STATE:VARIABLE]

	call asminject_wait_for_value_at_address
	
	pop edi	
	pop esi
	
	leave
	ret
	
// END: asminject_wait_for_script_state
