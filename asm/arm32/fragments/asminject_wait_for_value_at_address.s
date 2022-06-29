// BEGIN: asminject_wait_for_value_at_address
// wait for a particular word to be set at a particular address
// e.g. for checking script communication state variable
// r0 = address to check
// r1 = value to wait for

// import reusable code fragments 
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

asminject_wait_for_value_at_address:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	// register to load data at address into
	push {r10}
	// address to check
	push {r0}

asminject_wait_for_value_at_address_wait_loop:
	ldr r10, [r0]
	cmp r10, r1
	beq asminject_wait_for_value_at_address_done_looping

	push {r0}
	push {r1}
	// r0 = number of seconds to sleep
	// r1 = number of nanoseconds to sleep
	mov r0, #1
	mov r1, #1
	bl asminject_nanosleep
	pop {r1}
	pop {r0}

	b asminject_wait_for_value_at_address_wait_loop
	
asminject_wait_for_value_at_address_done_looping:
	
	pop {r0}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
	
// END: asminject_wait_for_value_at_address
