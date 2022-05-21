// BEGIN: asminject_libc_fread
// wrapper for the libc fread function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for fread is size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );
// if your libc has a different signature for fread, this code will probably fail
// rdi = pointer to buffer
// rsi = element size
// rdx = number of elements
// rcx = source file handle
// rax will contain the number of bytes read when this function returns

asminject_libc_fread:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push r14
	
	mov r9, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fread@@GLIBC.+:RELATIVEOFFSET]
	call r9

	pop r14
	pop r9
	leave
	ret
	
// END: asminject_libc_fread