// BEGIN: asminject_libpthread_pthread_exit
// wrapper for the libpthread pthread_exit function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_exit is noreturn void pthread_exit(void *retval);
// if your libpthread has a different signature for pthread_exit, this code will probably fail
// rdi = return value (generally 0 is fine)

asminject_libpthread_pthread_exit:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	mov r9, [SYMBOL_ADDRESS:^pthread_exit($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9
	
	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop r9
	leave
	ret
// END: asminject_libpthread_pthread_exit