# Threaded version of dlinject.s
# Same caveats as execute_precompiled_threaded.s

jmp post_load_library

load_library:
	// BEGIN: call dlopen() against the specified library
	push r14
	lea rdi, library_path[rip]
    mov rsi, 2              # mode (RTLD_NOW)
	mov rdx, [BASEADDRESS:.+/libdl-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:dlopen@@GLIBC_2.2.5:RELATIVEOFFSET]
	xor rcx, rcx
    mov r9, [BASEADDRESS:.+/libdl-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:dlopen@@GLIBC_2.2.5:RELATIVEOFFSET]
	call r9
	pop r14
	// END: call dlopen()

post_load_library:
	mov rcx, 0
	lea rax, load_library[rip]
	mov rdx, rax
	mov rsi, 0
	mov rax, arbitrary_read_write_data_address[rip]
	mov rdi, rax
	mov r9, [BASEADDRESS:.+/libpthread-[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:pthread_create@@GLIBC_2.2.5:RELATIVEOFFSET]
	call r9
	
[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:
	
# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"
