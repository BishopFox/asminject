	// Open source file
	push r14
	mov eax, 2            		# SYS_OPEN
	lea edi, sourcefile[eip]  	# file path
	xor esi, esi          		# flags (O_RDONLY)
	xor edx, edx          		# mode
	syscall
	mov r13, eax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	pop r14
	
	// Open destination file
	push r14
	push r13
	mov eax, 2             		# SYS_OPEN
	lea edi, destfile[eip]  	# file path
	mov esi, 0x42          		# flags (O_RDWR | O_CREAT)
	mov edx, 0777          		# make destination world-writable
	syscall
	mov r12, eax  # store file descriptor in r12 rather than a variable to avoid attempts to write to executable memory
	pop r13
	pop r14

	// create a stack variable to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	mov eax, 0
	push eax
	mov r15, esp

	push r15
	push r14
	push r13
	push r12

copyByteLoop:

	// read a single byte at a time to avoid more complex logic
	mov eax, 0		# SYS_READ
	mov edi, r13	# file descriptor
	mov esi, r15	# buffer address
	mov edx, 1		# number of bytes to read
	syscall

	// if no char was read (usually end-of-file), processing is complete
	cmp eax, 0
	jz doneCopying

	// write the byte to the destination file
	mov eax, 1		# SYS_WRITE      
	mov edi, r12	# file descriptor
	mov esi, r15	# buffer address
	mov edx, 1		# number of bytes to write
	syscall

	jmp copyByteLoop

doneCopying:

	// discard the buffer stack variable
	pop eax
	
	pop r12
	pop r13
	pop r14
	pop r15

	// close file handles
	mov ebx, r13
	mov eax, 6  # sys_close
	push r12
	syscall
	pop r12
	mov ebx, r12
	mov eax, 6  # sys_close
	syscall
	
SHELLCODE_SECTION_DELIMITER
	
sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"

