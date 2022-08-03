// BEGIN: asminject_libpthread_pthread_join
// wrapper for the libpthread pthread_join function
// tested with libpthread
// Assumes the signature for pthread_join is int pthread_join(pthread_t thread, void **retval);
// if your libpthread has a different signature for pthread_join, this code will probably fail
// edi = thread structure                               
// esi = return value pointer (generally 0 is fine)

// the 32-bit x86 version of calling pthread_join is handled like this:
// subtract 0x8 from the stack pointer
// push the arguments to the stack in reverse order:
// * return value
// * address of the thread ID value
// Call the pthread_join function

asminject_libpthread_pthread_join:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	sub esp, 0x8
	push esi
	push edi
	
	mov edx, [SYMBOL_ADDRESS:^pthread_join($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx
	
	add esp, 0x10
	
	pop edx
	leave
	ret
// END: asminject_libpthread_pthread_join