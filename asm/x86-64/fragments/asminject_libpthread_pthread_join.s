// BEGIN: asminject_libpthread_pthread_join
// wrapper for the libpthread pthread_join function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_join is int pthread_join(pthread_t thread, void **retval);
// if your libpthread has a different signature for pthread_join, this code will probably fail
// rdi = thread structure                               
// rsi = return value pointer (generally 0 is fine)

asminject_libpthread_pthread_join:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	mov r9, [SYMBOL_ADDRESS:^pthread_join($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9

	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop r9
	leave
	ret
// END: asminject_libpthread_pthread_join