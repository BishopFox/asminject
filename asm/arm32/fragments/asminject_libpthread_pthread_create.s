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
	push {r8}
	
	// ensure the stack is 16-byte aligned, because some versions of libpthread are super picky about this
asminject_libpthread_pthread_create_align_stack:
	mov r8, sp
	sub r8, r8, #0x4	// one more register will be pushed onto the stack after this check
	and r9, r8, #0x8
	cmp r9, #8
	bne asminject_libpthread_pthread_create_push_one
	push {r8}
	push {r8}
	asminject_libpthread_pthread_create_push_one:
	and r9, r8, #0x4
	cmp r9, #4
	bne asminject_libpthread_pthread_create_load_address
	push {r8}

asminject_libpthread_pthread_create_load_address:
	push {r8}

// Load the address of libpthread pthread_create into r10
	ldr r10, [pc]
	b asminject_libpthread_pthread_create_call_inner

asminject_libpthread_pthread_create_address:
	.word [SYMBOL_ADDRESS:^pthread_create($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	.balign 4

asminject_libpthread_pthread_create_call_inner:
	// r0 and r2 will already be set
	mov r1, #0x0
	mov r3, #0x0
	blx r10

	pop {r8}
	
// remove extra value from the stack if one was added to align it

	and r9, r8, #0x8
	cmp r9, #8
	bne asminject_libpthread_pthread_create_pop_one
	pop {r8}
	pop {r8}
asminject_libpthread_pthread_create_pop_one:
	and r9, r8, #0x4
	cmp r9, #4
	bne asminject_libpthread_pthread_create_cleanup
	pop {r8}

asminject_libpthread_pthread_create_cleanup:
	pop {r8}
	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libpthread_pthread_create