// BEGIN: asminject_libc_or_libdl_dlopen
// wrapper for the libdl dlopen function
// tested with libdl 
// Assumes the signature for dlopen is void *dlopen([const] char *filename, int flags);
// if your libdl has a different signature for dlopen, this code will probably fail
// edi = string containing .so file path

// the 32-bit x86 version of calling dlopen is handled like this:
// subtract 0x8 from the stack pointer
// push the arguments to the stack in reverse order:
// * flags: 0x2 (RTLD_NOW)
// * pointer to string containing path to .so file
// Call the dlopen function
// add 0x10 to the stack pointer

asminject_libc_or_libdl_dlopen:	
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	//sub esp, 0x8
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 2, so subtract 0x8
	sub esp, 0x8
	
	// mode (RTLD_NOW)
	push 0x2              
	push edi

	mov edx, [SYMBOL_ADDRESS:^dlopen($|@@.+):IN_BINARY:.+/lib(dl|c)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call edx
	
	// pop two arguments + alignment placeholder off of stack:
	add esp, 0x10
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	//add esp, 0x10
	
	pop edx
	leave
	ret
// END: asminject_libc_or_libdl_dlopen