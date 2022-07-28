// BEGIN: asminject_libpthread_pthread_create
// wrapper for the libpthread pthread_create function
// tested with libpthread
// Assumes the signature for pthread_create is int pthread_create(pthread_t *restrict thread, [const] pthread_attr_t *restrict attr, void *(*start_routine)(void *), void *restrict arg);
// if your libpthread has a different signature for pthread_create, this code will probably fail
// edi = pointer to a memory location to represent the pthread_t struct (basically just somewhere you are not using for something else, can be all nulls)
// edx = pointer to function to launch in a separate thread

asminject_libpthread_pthread_create:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	mov ecx, 0
	mov esi, 0
	mov edx, [BASEADDRESS:.+/libpthread[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^pthread_create($|@@.+):RELATIVEOFFSET]
	call edx
	
	pop edx
	leave
	ret

// END: asminject_libpthread_pthread_create