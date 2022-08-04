// BEGIN: asminject_libc_or_libdl_dlopen
// wrapper for the libc/libdl dlopen function
// tested with libdl 2.28 and 2.33
// Assumes the signature for dlopen is void *dlopen([const] char *filename, int flags);
// if your libdl has a different signature for dlopen, this code will probably fail
// rdi = string containing .so file path

asminject_libc_or_libdl_dlopen:	
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push r8
	
	// ensure the stack is 16-byte aligned
	mov r8, rsp
	and r8, 0x8
	cmp r8, 0x8
	je asminject_libc_or_libdl_dlopen_call_inner
	push r8

asminject_libc_or_libdl_dlopen_call_inner:
	push r8
	mov rsi, 2              # mode (RTLD_NOW)
	mov r9, [SYMBOL_ADDRESS:^dlopen($|@@.+):IN_BINARY:.+/lib(dl|c)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9
	
	pop r8
	
	// remove extra value from the stack if one was added to align it
	cmp r8, 0x8
	je asminject_libc_or_libdl_dlopen_cleanup
	pop r8

asminject_libc_or_libdl_dlopen_cleanup:
	
	pop r8
	pop r9
	leave
	ret
// END: asminject_libc_or_libdl_dlopen