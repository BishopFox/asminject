// BEGIN: asminject_libpthread_pthread_exit
// wrapper for the libpthread pthread_exit function
// tested with libpthread 
// Assumes the signature for pthread_exit is noreturn void pthread_exit(void *retval);
// if your libpthread has a different signature for pthread_exit, this code will probably fail
// edi = return value (generally 0 is fine)

// the 32-bit x86 version of calling pthread_exit is handled like this:
// subtract 0xc from the stack pointer
// push the arguments to the stack in reverse order:
// * return value
// Call the pthread_exit function

asminject_libpthread_pthread_exit:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	
	sub esp, 0xc
	
	push edi
	
	mov edx, [FUNCTION_ADDRESS:^pthread_exit($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	call edx
	
	//leave
	//ret
// END: asminject_libpthread_pthread_exit