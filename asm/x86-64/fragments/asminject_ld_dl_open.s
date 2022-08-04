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
	
	[INLINE:stack_align-r8-pre.s:INLINE]
	
	// rdi = pointer to file path
	// rsi = mode 
	// rdx = caller_dlopen
	// rcx = nsid
	// r8 = argc
	// r9 = argv
	// stack1 = env
	
	// store a pointer to the library path to use as a fake argv and env
	//mov rdx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	//add rdx, 0x500
	//mov [rdx], rdi
	//mov r9, rdx
	//push rdx
	
	// subtract 8 from the stack pointer to keep it 16-byte aligned
	// because one argument is pushed onto the stack for the next function call
	sub rsp, 0x8
	
	// these values obtained from symbols exported by libc:
	// deference pointer to environment variables
	mov r9, [SYMBOL_ADDRESS:^_environ$:IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	mov r9, [r9]
	push r9
	// deference pointer to argv
	mov r9, [SYMBOL_ADDRESS:^__libc_argv$:IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	mov r9, [r9]
	// deference pointer to argc
	mov r8, [SYMBOL_ADDRESS:^__libc_argc$:IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	mov r8, [r8]
	
	mov rsi, 0x80000002              # mode (RTLD_NOW|value observed in gdb)
	//mov rsi, 0x2              # mode (RTLD_NOW)
	mov rax, [SYMBOL_ADDRESS:^_dl_open($|@@.+):IN_BINARY:.+/ld(-linux|)[a-z\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	mov rdx, [VARIABLE:READ_EXECUTE_ADDRESS:VARIABLE]
	mov rcx, -2
	//mov rcx, 0
	//mov r8, 1
	call rax

	//pop rax
	//pop rax
	//pop r9
	
	add rsp, 0x8
	
	[INLINE:stack_align-r8-post.s:INLINE]
	
	pop r9
	pop r8
	pop rdx
	pop rcx
	
	leave
	ret

// END: asminject_ld_dl_open
