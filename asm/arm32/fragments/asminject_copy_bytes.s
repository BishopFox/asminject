// BEGIN: asminject_copy_bytes
// very basic byte-copying function
// r0 = source address
// r1 = destination address
// r2 = number of bytes to copy

asminject_copy_bytes:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r3}
	push {r4}
	mov r3, #0x0
	
asminject_copy_bytes_loop:

	ldrb r4, [r0, r3]
	strb r4, [r1, r3]

	// increment the counter
	// as well as the source and destination addresses
	add r3, r3, #0x1
	//add r0, r0, #0x1
	//add r1, r1, #0x1
	// check to see if all bytes have been copied
	cmp r2, r3
	beq asminject_copy_bytes_done
	b asminject_copy_bytes_loop
	
asminject_copy_bytes_done:

	pop {r4}
	pop {r3}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_copy_bytes
