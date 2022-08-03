// BEGIN: asminject_libc_fopen
// wrapper for the libc fopen function
// tested with libc 
// Assumes the signature for fopen is FILE * fopen([const] char * filename, [const] char * mode);
// if your libc has a different signature for fopen, this code will probably fail
// edi = path to file
// esi = mode string ("r\0", "w\0", etc.)
// eax will contain the handle when this function returns

// the 32-bit x86 version of calling fopen is handled like this:
// subtract 0x8 from the stack pointer
// push the arguments to the stack in reverse order:
// * pointer to mode string
// * pointer to path string
// Call the fopen function
// add 0x10 to the stack pointer
// EAX contains the resulting file handle number

asminject_libc_fopen:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx

	sub esp, 0x8
	push esi
	push edi
	
	mov edx, [SYMBOL_ADDRESS:^fopen($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx

	add esp, 0x10
	
	pop edx
	leave
	ret

// END: asminject_libc_fopen