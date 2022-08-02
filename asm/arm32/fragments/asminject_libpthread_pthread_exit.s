// BEGIN: asminject_libpthread_pthread_exit
// wrapper for the libpthread pthread_exit function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_exit is noreturn void pthread_exit(void *retval);
// if your libpthread has a different signature for pthread_exit, this code will probably fail
// r0 = return value (generally 0 is fine)

asminject_libpthread_pthread_exit:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}

// Load the address of libpthread pthread_exit into r10
	ldr r10, [pc]
	b asminject_libpthread_pthread_exit_call_pthread_exit

asminject_libpthread_pthread_exit_address:
	.word [FUNCTION_ADDRESS:^pthread_exit($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	.balign 4
	
asminject_libpthread_pthread_exit_call_pthread_exit:
	// r0 will already be set
	blx r10

	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libpthread_pthread_exit