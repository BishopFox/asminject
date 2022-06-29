// BEGIN: asminject_set_payload_state
// set a payload state value
// r0 = communications address
// r1 = value to set

asminject_set_payload_state:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	// communications address
	push {r0}
	
	add r0, r0, #[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_STATE:VARIABLE]
	str r1, [r0]
		
	pop {r0}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
	
// END: asminject_set_payload_state
