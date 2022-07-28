// BEGIN: asminject_libpthread_pthread_exit
// wrapper for the libpthread pthread_exit function
// tested with libpthread 
// Assumes the signature for pthread_exit is noreturn void pthread_exit(void *retval);
// if your libpthread has a different signature for pthread_exit, this code will probably fail
// edi = return value (generally 0 is fine)

asminject_libpthread_pthread_exit:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	mov edx, [BASEADDRESS:.+/libpthread[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^pthread_exit($|@@.+):RELATIVEOFFSET]
	call edx
	
	pop edx
	leave
	ret
// END: asminject_libpthread_pthread_exit