// BEGIN: asminject_libpthread_pthread_detach
// wrapper for the libpthread pthread_detach function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_detach is int pthread_detach(pthread_t thread);
// if your libpthread has a different signature for pthread_detach, this code will probably fail
// edi = pthread_t struct

asminject_libpthread_pthread_detach:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	mov edx, [BASEADDRESS:.+/libpthread[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^pthread_detach($|@@.+):RELATIVEOFFSET]
	call edx
	
	pop edx
	leave
	ret
// END: asminject_libpthread_pthread_detach