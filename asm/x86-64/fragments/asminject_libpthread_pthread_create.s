// BEGIN: asminject_libpthread_pthread_create
// wrapper for the libpthread pthread_create function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_create is int pthread_create(pthread_t *restrict thread, [const] pthread_attr_t *restrict attr, void *(*start_routine)(void *), void *restrict arg);
// if your libpthread has a different signature for pthread_create, this code will probably fail
// rdi = pointer to a memory location to represent the pthread_t struct (basically just somewhere you are not using for something else, can be all nulls)
// rdx = pointer to function to launch in a separate thread

asminject_libpthread_pthread_create:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	[INLINE:stack_align-r8-pre.s:INLINE]
	// rdi = pointer to a memory location to represent the pthread_t struct
	// rsi = attributes 
	// rdx = pointer to function to launch in a separate thread
	// rcx = arguments
	
	mov rcx, 0
	mov rsi, 0
	mov r9, [SYMBOL_ADDRESS:^pthread_create($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9

	[INLINE:stack_align-r8-post.s:INLINE]
	pop r9
	leave
	ret

// END: asminject_libpthread_pthread_create