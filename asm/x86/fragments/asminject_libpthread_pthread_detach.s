// BEGIN: asminject_libpthread_pthread_detach
// wrapper for the libpthread pthread_detach function
// tested with libpthread 2.28 and 2.33
// Assumes the signature for pthread_detach is int pthread_detach(pthread_t thread);
// if your libpthread has a different signature for pthread_detach, this code will probably fail
// edi = pthread_t struct

// the 32-bit x86 version of calling pthread_detach is handled like this:
// subtract 0xc from the stack pointer
// push the arguments to the stack in reverse order:
// * address of the thread ID value
// Call the pthread_detach function
// add 0x10 to the stack pointer

asminject_libpthread_pthread_detach:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	sub esp, 0xc
	push edi
	
	mov edx, [BASEADDRESS:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^pthread_detach($|@@.+):RELATIVEOFFSET]
	call edx
	
	add esp, 0x10
	
	pop edx
	leave
	ret
// END: asminject_libpthread_pthread_detach