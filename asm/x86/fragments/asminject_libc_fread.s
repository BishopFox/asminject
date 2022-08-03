// BEGIN: asminject_libc_fread
// wrapper for the libc fread function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fread is size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );
// if your libc has a different signature for fread, this code will probably fail
// edi = pointer to buffer
// esi = element size
// eax = number of elements
// ebx = source file descriptor
// eax will contain the number of bytes read when this function returns

// the 32-bit x86 version of calling fread is handled like this:
// push the arguments to the stack in reverse order:
// * pointer to file descriptor
// * number of elements
// * element size
// * pointer to read buffer
// Call the fread function
// add 0x10 to the stack pointer

asminject_libc_fread:
	push ebp
	mov ebp, esp	
	sub esp, 0x10
	push edx
	
	push ebx
	push eax
	push esi
	push edi
	
	mov edx, [SYMBOL_ADDRESS:^fread($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx

	add esp, 0x10

	pop edx
	leave
	ret
	
// END: asminject_libc_fread