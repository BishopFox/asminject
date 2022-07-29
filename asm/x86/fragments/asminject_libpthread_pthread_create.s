// BEGIN: asminject_libpthread_pthread_create
// wrapper for the libpthread pthread_create function
// tested with libpthread
// Assumes the signature for pthread_create is int pthread_create(pthread_t *restrict thread, [const] pthread_attr_t *restrict attr, void *(*start_routine)(void *), void *restrict arg);
// if your libpthread has a different signature for pthread_create, this code will probably fail
// edi = pointer to a memory location to represent the pthread_t struct (basically just somewhere you are not using for something else, can be all nulls)
// edx = pointer to function to launch in a separate thread

// the 32-bit x86 version of calling pthread_create is handled like this:
// push the arguments to the stack in reverse order:
// * arg: null
// * address of the function to launch in a separate thread
// * attr: null
// * address of the thread ID value
// Call the pthread_create function
// add 0x10 to the stack pointer

asminject_libpthread_pthread_create:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	push 0x0
	push edx
	push 0x0
	push edi
	
	mov edx, [BASEADDRESS:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^pthread_create($|@@.+):RELATIVEOFFSET]
	call edx
	
	add esp, 0x10
	
	pop edx
	leave
	ret

// END: asminject_libpthread_pthread_create