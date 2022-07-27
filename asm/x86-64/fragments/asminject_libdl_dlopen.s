// BEGIN: asminject_libdl_dlopen
// wrapper for the libdl dlopen function
// tested with libdl 2.28 and 2.33
// Assumes the signature for dlopen is void *dlopen([const] char *filename, int flags);
// if your libdl has a different signature for dlopen, this code will probably fail
// rdi = string containing .so file path

asminject_libdl_dlopen:	
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	
	mov rsi, 2              # mode (RTLD_NOW)
	mov r9, [BASEADDRESS:.+/libdl[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS] + [RELATIVEOFFSET:^dlopen($|@@.+):RELATIVEOFFSET]
	call r9
	
	pop r9
	leave
	ret
// END: asminject_libdl_dlopen