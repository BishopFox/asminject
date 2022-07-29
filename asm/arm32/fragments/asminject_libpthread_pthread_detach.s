// BEGIN: asminject_libpthread_pthread_detach
// wrapper for the libpthread pthread_detach function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_detach is int pthread_detach(pthread_t thread);
// if your libpthread has a different signature for pthread_detach, this code will probably fail
// r0 = pthread_t struct

asminject_libpthread_pthread_detach:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
	push {r10}
	push {r9}

// Load the base address of libpthread into r10
	ldr r10, [pc]
	b asminject_libpthread_pthread_detach_load_pthread_detach_offset

asminject_libpthread_pthread_detach_base_address:
	.word [BASEADDRESS:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	.balign 4
	
// Load the relative offset of pthread_detach into r9
asminject_libpthread_pthread_detach_load_pthread_detach_offset:
	ldr r9, [pc]
	b asminject_libpthread_pthread_detach_call_pthread_detach

asminject_libpthread_pthread_detach_pthread_detach_offset:
	.word [RELATIVEOFFSET:^pthread_detach($|@@.+):RELATIVEOFFSET]
	.balign 4

asminject_libpthread_pthread_detach_call_pthread_detach:
	// r9 = relative offset + base address
	add r9, r9, r10
	// r0 will already be set
	blx r9

	pop {r9}
	pop {r10}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_libpthread_pthread_detach