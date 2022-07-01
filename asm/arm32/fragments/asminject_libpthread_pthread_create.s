// BEGIN: asminject_libpthread_pthread_create
// wrapper for the libpthread pthread_create function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_create is int pthread_create(pthread_t *restrict thread, [const] pthread_attr_t *restrict attr, void *(*start_routine)(void *), void *restrict arg);
// if your libpthread has a different signature for pthread_create, this code will probably fail
// r0 = pointer to a memory location to represent the pthread_t struct (basically just somewhere you are not using for something else, can be all nulls)
// r2 = pointer to function to launch in a separate thread

asminject_libpthread_pthread_create:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}
	push {r9}

// Load the base address of libpthread into r10
	ldr r10, [pc]
	b asminject_libpthread_pthread_create_load_pthread_create_offset

asminject_libpthread_pthread_create_base_address:
	.word [BASEADDRESS:.+/libpthread-[0-9\.]+.so$:BASEADDRESS]
	.balign 4
	
// Load the relative offset of pthread_create into r9
asminject_libpthread_pthread_create_load_pthread_create_offset:
	ldr r9, [pc]
	b asminject_libpthread_pthread_create_call_pthread_create

asminject_libpthread_pthread_create_pthread_create_offset:
	.word [RELATIVEOFFSET:^pthread_create($|@@.+):RELATIVEOFFSET]
	.balign 4

asminject_libpthread_pthread_create_call_pthread_create:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0 and r2 will already be set
	mov r1, #0x0
	mov r3, #0x0
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libpthread_pthread_create