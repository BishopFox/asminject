// BEGIN: asminject_wait_for_script_state
// wait for the script to set a particular state value
// r0 = communications address
// r1 = value to wait for

// import reusable code fragments 
[FRAGMENT:asminject_wait_for_value_at_address.s:FRAGMENT]

asminject_wait_for_script_state:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r0}
	push {r1}
	
	add r0, r0, #[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_STATE:VARIABLE]

	bl asminject_wait_for_value_at_address
		
	pop {r1}
	pop {r0}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_wait_for_script_state
