// BEGIN: asminject_libdl_dlopen
// wrapper for the libdl dlopen function
// tested with libdl 2.28 and 2.33
// Assumes the signature for dlopen is void *dlopen([const] char *filename, int flags);
// if your libdl has a different signature for dlopen, this code will probably fail
// edi = string containing .so file path

asminject_libdl_dlopen:	
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push edx
	
	mov esi, 2              # mode (RTLD_NOW)
	mov edx, [BASEADDRESS:.+/libdl[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS]
	add edx, [RELATIVEOFFSET:^dlopen($|@@.+):RELATIVEOFFSET]
	call edx
	
	pop edx
	leave
	ret
// END: asminject_libdl_dlopen