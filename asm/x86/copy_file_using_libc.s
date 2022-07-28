[FRAGMENT:asminject_libc_fopen.s:FRAGMENT]
[FRAGMENT:asminject_libc_fclose.s:FRAGMENT]
[FRAGMENT:asminject_libc_fread.s:FRAGMENT]
[FRAGMENT:asminject_libc_fwrite.s:FRAGMENT]

	// BEGIN: call LIBC fopen against the source file
	// like all of the other 32-bit x86 code, this uses the inline-data workaround
	// because the architecture has no equivalent of RIP-relative references	

	call copy_using_libc_get_ro_get_next
copy_using_libc_get_ro_get_next:
	# set EAX to the address of the read-only mode string "r"
	pop esi
	add esi, 6
	jmp copy_using_libc_get_source_string
	
read_only_string:
	.ascii "r\0"

copy_using_libc_get_source_string:
	call copy_using_libc_get_source_get_next
copy_using_libc_get_source_get_next:
	# set EAX to the address of the source file path string
	pop edi
	add edi, 6
	jmp copy_using_libc_fopen_source

sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"

copy_using_libc_fopen_source:
	nop
	call asminject_libc_fopen
    mov edx, eax          # store file descriptor in edx rather than a variable to avoid attempts to write to executable memory
	// END: call LIBC fopen
	
	// BEGIN: call LIBC fopen against the destination file
	
	call copy_using_libc_get_wo_get_next
copy_using_libc_get_wo_get_next:
	# set EAX to the address of the read-only mode string "r"
	pop esi
	add esi, 6
	jmp copy_using_libc_get_dest_string
	
write_only_string:
	.ascii "w\0"

copy_using_libc_get_dest_string:
	call copy_using_libc_get_dest_get_next
copy_using_libc_get_dest_get_next:
	# set EAX to the address of the source file path string
	pop edi
	add edi, 6
	jmp copy_using_libc_fopen_dest

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"

copy_using_libc_fopen_dest:
	nop
	push edx
	call asminject_libc_fopen
    mov ecx, eax          # store file descriptor in edx rather than a variable to avoid attempts to write to executable memory
	pop edx
	// END: call LIBC fopen

copyLoop:

	push eax
	push ebx
	push ecx
	push edx

	// BEGIN: call LIBC fread against the source file
	push ecx	# save destination FD in case fread stops on it
	mov edi, 	[VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]	# buffer - read/write area allocated earlier
	add edi, 0x1000	# don't overwrite anything else that's in it
	mov esi, 1		# element size
	mov eax, 256	# number of elements
	mov ebx, edx	# file descriptor
	call asminject_libc_fread
    # result is in eax
	pop ecx	# restore destination FD
	// END: call LIBC fread
	
	// if no bytes were read (usually end-of-file), processing is complete
	cmp eax, 0
	jle doneCopying
	
	// BEGIN: call LIBC fwrite against the destination file with the number of elements read by fread()
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]	# buffer - read/write area allocated earlier
	add edi, 0x1000	# don't overwrite anything else that's in it
	mov esi, 1		# element size
	# eax already contains number of elements read
	mov ebx, ecx	# file descriptor
	call asminject_libc_fwrite
	# eax contains number of bytes written
	
	// END: call LIBC fwrite

	pop edx
	pop ecx
	pop ebx
	pop eax

	jmp copyLoop

doneCopying:
	# have to repeat these here because they won't be called if the jle instruction jumps out of the loop
	pop edx
	pop ecx
	pop ebx
	pop eax

	// close file handles using fclose()
	
	// BEGIN: call LIBC fclose against the destination file
	# save source FD in case fclose stops on it
	push eax
	push ebx
	push ecx
	push edx
	mov edi, ecx	# file descriptor
	call asminject_libc_fclose
	pop edx
	pop ecx
	pop ebx
	pop eax
	// END: call LIBC fclose
	
	// BEGIN: call LIBC fclose against the source file
	push eax
	push ebx
	push ecx
	push edx
	mov edi, edx	# file descriptor
	call asminject_libc_fclose
	pop edx
	pop ecx
	pop ebx
	pop eax
	// END: call LIBC fclose

SHELLCODE_SECTION_DELIMITER
	

