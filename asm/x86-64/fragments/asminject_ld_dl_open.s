// BEGIN: asminject_ld_dl_open
// wrapper for the ld _dl_open function
// tested with ld 
// Assumes the signature for _dl_open is void * _dl_open(const char *file, int mode, const void *caller_dlopen, Lmid_t nsid, int argc, char *argv[], char *env[]);
// if your ld has a different signature for _dl_open, this code will probably fail
// rdi = pointer to string containing .so file path

asminject_ld_dl_open:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	
	push rcx
	push rdx
	push r8
	push r9
	
	// rdi = pointer to file path
	// rsi = mode 
	// rdx = caller_dlopen
	// rcx = nsid
	// r8 = argc
	// r9 = argv
	// stack1 = env
	
	// store a pointer to the library path to use as a fake argv and env
	mov rdx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add rdx, 0x500
	mov [rdx], rdi
	mov r9, rdx
	push rdx
	
	mov rsi, 2              # mode (RTLD_NOW)
	mov r9, [FUNCTION_ADDRESS:^_dl_open($|@@.+):IN_BINARY:.+/ld(-linux|)[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	mov rdx, r9
	mov rcx, -1
	mov r8, 1
	call r9

	pop rdx
	
	pop r9
	pop r8
	pop rdx
	pop rcx
	
	leave
	ret
	
	
	
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
	// hardcoded nsid value observed in gdb:
	mov eax, 0xfffffffe
	push eax
	mov edx, [FUNCTION_ADDRESS:^_dl_open($|@@.+):IN_BINARY:.+/ld(-linux|)[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
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
