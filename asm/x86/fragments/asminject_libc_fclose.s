// BEGIN: asminject_libc_fclose
// wrapper for the libc fclose function
// tested with libc 
// Assumes the signature for fclose is int fclose(FILE * stream);
// if your libc has a different signature for fclose, this code will probably fail
// edi = file handle

// the 32-bit x86 version of calling fclose is handled like this:
// subtract 0xc from the stack pointer
// push the argument to the stack:
// * pointer to file descriptor
// Call the fclose function
// add 0x10 to the stack pointer

asminject_libc_fclose:
	push ebp
	mov ebp, esp	
	sub esp, 0x10
	push edx
	
	sub esp, 0xc
	
	push edi
	
	mov edx, [BASEADDRESS:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^fclose($|@@.+):RELATIVEOFFSET]
	call edx

	add esp, 0x10

	pop edx
	leave
	ret
	
// END: asminject_libc_fclose