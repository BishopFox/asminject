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
	push {r9}

// Load the base address of libpthread into r10
	ldr r10, [pc]
	b asminject_libpthread_pthread_exit_load_pthread_exit_offset

asminject_libpthread_pthread_exit_base_address:
	.word [BASEADDRESS:.+/libpthread-[0-9\.]+.so$:BASEADDRESS]
	.balign 4
	
// Load the relative offset of pthread_exit into r9
asminject_libpthread_pthread_exit_load_pthread_exit_offset:
	ldr r9, [pc]
	b asminject_libpthread_pthread_exit_call_pthread_exit

asminject_libpthread_pthread_exit_pthread_exit_offset:
	.word [RELATIVEOFFSET:pthread_exit@@GLIBC.+:RELATIVEOFFSET]
	.balign 4

asminject_libpthread_pthread_exit_call_pthread_exit:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0 will already be set
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libpthread_pthread_exit