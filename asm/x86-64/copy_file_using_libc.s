	// BEGIN: call LIBC fopen against the source file
	push r14
	push rbx
	lea rax, sourcefile[rip]
	lea rdi, sourcefile[rip]
    lea rsi, read_only_string[rip]
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fopen@@GLIBC.+:RELATIVEOFFSET]
	call rbx
    mov r13, rax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	pop rbx
	pop r14
	// END: call LIBC fopen
	
	// BEGIN: call LIBC fopen against the destination file
	push r14
	push r13
	push rbx
	lea rax, destfile[rip]
	lea rdi, destfile[rip]
    lea rsi, write_only_string[rip]
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fopen@@GLIBC.+:RELATIVEOFFSET]
	call rbx
    mov r10, rax          # store file descriptor in r10 rather than a variable to avoid attempts to write to executable memory
	pop rbx
	pop r13
	pop r14
	// END: call LIBC fopen

	// push rax onto the stack 8 times (= 64 bytes) to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	mov rax, 0
	push rax
	push rax
	push rax
	push rax
	push rax
	push rax
	push rax
	push rax
	mov r15, rsp

copyLoop:

	// BEGIN: call LIBC fread against the source file
	push r15
	push r14
	push r13
	push r10
	push rbx
	mov rcx, r13	# file descriptor
	mov rdx, 64		# number of elements
	mov esi, 1		# element size
	mov rax, r15	# buffer
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fread@@.+:RELATIVEOFFSET]
	call rbx
    mov r12, rax    # result
	pop rbx
	pop r10
	pop r13
	pop r14
	pop r15
	// END: call LIBC fread
	
	// if no bytes were read (usually end-of-file), processing is complete
	cmp r12, 0
	jle doneCopying
	
	// BEGIN: call LIBC fwrite against the destination file with the number of elements read by fread()
	push r15
	push r14
	push r13
	push r10
	push rbx
	mov rcx, r10	# file descriptor
	mov rdx, r12	# number of elements
	mov esi, 1		# element size
	mov rax, r15	# buffer
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fwrite@@.+:RELATIVEOFFSET]
	call rbx
    mov r12, rax    # result
	pop rbx
	pop r10
	pop r13
	pop r14
	pop r15
	// END: call LIBC fwrite

	jmp copyLoop

doneCopying:

	// discard the buffer stack variables
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax

	// close file handles using fclose()
	
	// BEGIN: call LIBC fclose against the destination file with the number of elements read by fread()
	push r15
	push r14
	push r13
	push r10
	push rbx
	mov rax, r13	# file descriptor
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fclose@@.+:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r10
	pop r13
	pop r14
	pop r15
	// END: call LIBC fclose
	
	// BEGIN: call LIBC fclose against the destination file with the number of elements read by fread()
	push r15
	push r14
	push r13
	push r10
	push rbx
	mov rax, r10	# file descriptor
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fclose@@.+:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r10
	pop r13
	pop r14
	pop r15
	// END: call LIBC fclose

SHELLCODE_SECTION_DELIMITER
	
sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"

read_only_string:
	.ascii "r\0"

write_only_string:
	.ascii "w\0"
