// BEGIN: asminject_set_memory_addresses
// set a payload state value
// r0 = communications address
// r1 = read/execute base address
// r2 = read/write base address

asminject_set_memory_addresses:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20

	// communications address
	push {r10}
		
	mov r10, r0
	add r10, r10, #[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_EXECUTE_BASE_ADDRESS:VARIABLE]
	str r1, [r10]
	
	mov r10, r0
	add r10, r10, #[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_WRITE_BASE_ADDRESS:VARIABLE]
	str r2, [r10]
		
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_set_memory_addresses
