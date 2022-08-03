// BEGIN: asminject_ld_dl_open
// wrapper for the ld _dl_open function
// tested with ld 
// Assumes the signature for _dl_open is void * _dl_open(const char *file, int mode, const void *caller_dlopen, Lmid_t nsid, int argc, char *argv[], char *env[]);
// if your ld has a different signature for _dl_open, this code will probably fail
// edi = string containing .so file path

// after much investigation in gdb, the 32-bit x86 version of calling _dl_open is handled like this:
// subtract 0x4 from the stack pointer
// push the arguments to the stack in reverse order:
// * env: pointer to a pointer array containing one dummy value (pointer to the library path)
// * argv: pointer to a pointer array containing one dummy value (pointer to the library path)
// * argc: 1
// * nsid: 0xfffffffe because that's how it appeared when viewing real calls to this function in gdb
// * caller_dlopen: address of the _dl_open function itself
// * mode: 0x2	(RTLD_NOW)
// * pointer to string containing path to .so file
// Call the dlopen function
// add 0x3c to the stack pointer
// There are enough magic values in here that I recommend using the dlopen function
// in libdl or libc instead unless your Linux distribution doesn't expose it

asminject_ld_dl_open:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	
	// store a pointer to the library path to use as a fake argv and env
	mov edx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edx, 0x500
	mov [edx], edi
	
	sub esp, 0x4
	
	// set ecx to the address of this function
	call asminject_ld_dl_open_address_get_next
asminject_ld_dl_open_address_get_next:
	pop ecx
	sub ecx, 0xd
	jmp asminject_ld_dl_open_call_dl_open

asminject_ld_dl_open_call_dl_open:	

	// use the library path as a fake env value
	push edx
	
	// use the library path as a fake argv
	push edx
	
	// fake argc of 1
	mov eax, 0x1
	push eax
	// hardcoded nsid value of -2 observed in gdb:
	mov eax, 0xfffffffe
	push eax
	mov edx, [SYMBOL_ADDRESS:^_dl_open($|@@.+):IN_BINARY:.+/ld(-linux|)[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	push ecx
	// (RTLD_NOW)
	mov eax, 0x2
	// when observing a real call in gdb, the mode was OR'd with 0x80000000
	//or eax, 0x80000000
	// for debugging, the exact value observed in gdb - decodes to RTLD_LAZY | RTLD_DEEPBIND | RTLD_GLOBAL | 0x80000000
	//mov eax, 0x80000109
	push eax
	push edi
	call edx
	
	add esp, 0x3c
	
	leave
	ret
// END: asminject_ld_dl_open
