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
	
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 1, so subtract 0xc
	sub esp, 0xc
	
	push edi
	
	mov edx, [SYMBOL_ADDRESS:^pthread_exit($|@@.+):IN_BINARY:.+/lib(c|pthread)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx
	
	// pop one argument + alignment placeholder off of stack:
	add esp, 0x10
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	
	leave
	ret
// END: asminject_libpthread_pthread_exit