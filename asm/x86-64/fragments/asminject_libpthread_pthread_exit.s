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
	
	mov r9, [BASEADDRESS:.+/libpthread-[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:pthread_exit@@.+:RELATIVEOFFSET]
	call r9
	
	pop r9
	leave
	ret
// END: asminject_libpthread_pthread_exit