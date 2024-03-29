// BEGIN: asminject_libpthread_pthread_detach
// wrapper for the libpthread pthread_detach function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_detach is int pthread_detach(pthread_t thread);
// if your libpthread has a different signature for pthread_detach, this code will probably fail
// rdi = pthread_t struct

asminject_libpthread_pthread_detach:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	mov r9, [SYMBOL_ADDRESS:^pthread_detach($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9
	
	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop r9
	leave
	ret
// END: asminject_libpthread_pthread_detach