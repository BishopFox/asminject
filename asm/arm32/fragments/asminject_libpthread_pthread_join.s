// BEGIN: asminject_libpthread_pthread_join
// wrapper for the libpthread pthread_join function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_join is int pthread_join(pthread_t thread, void **retval);
// if your libpthread has a different signature for pthread_join, this code will probably fail
// r0 = thread structure                               
// r1 = return value pointer (generally 0 is fine)

asminject_libpthread_pthread_join:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}

// Load the base address of libpthread into r10
	ldr r10, [pc]
	b asminject_libpthread_pthread_join_call_pthread_join

asminject_libpthread_pthread_join_address:
	.word [FUNCTION_ADDRESS:^pthread_join($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	.balign 4
	
asminject_libpthread_pthread_join_call_pthread_join:
	// r0 will already be set
	blx r10
	
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libpthread_pthread_join