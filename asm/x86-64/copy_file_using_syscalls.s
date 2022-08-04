	// Open source file
	push r14
	mov rax, 2            		# SYS_OPEN
	lea rdi, sourcefile[rip]  	# file path
	xor rsi, rsi          		# flags (O_RDONLY)
	xor rdx, rdx          		# mode
	syscall
	mov r13, rax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	pop r14
	
	// Open destination file
	push r14
	push r13
	mov rax, 2             		# SYS_OPEN
	lea rdi, destfile[rip]  	# file path
	mov rsi, 0x42          		# flags (O_RDWR | O_CREAT)
	mov rdx, 0777          		# make destination world-writable
	syscall
	mov r12, rax  # store file descriptor in r12 rather than a variable to avoid attempts to write to executable memory
	pop r13
	pop r14

	// create a stack variable to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	mov rax, 0
	push rax
	mov r15, rsp

	push r15
	push r14
	push r13
	push r12

copyByteLoop:

	// read a single byte at a time to avoid more complex logic
	mov rax, 0		# SYS_READ
	mov rdi, r13	# file descriptor
	mov rsi, r15	# buffer address
	mov rdx, 1		# number of bytes to read
	syscall

	// if no char was read (usually end-of-file), processing is complete
	cmp rax, 0
	jz doneCopying

	// write the byte to the destination file
	mov rax, 1		# SYS_WRITE      
	mov rdi, r12	# file descriptor
	mov rsi, r15	# buffer address
	mov rdx, 1		# number of bytes to write
	syscall

	jmp copyByteLoop

doneCopying:

	// flush the output file buffer
	mov rax, 74		# SYS_FSYNC   
	mov rdi, r12	# file descriptor
	syscall

	// discard the buffer stack variable
	pop rax
	
	pop r12
	pop r13
	pop r14
	pop r15

	// close file handles
	mov rbx, r13
	mov rax, 6  # sys_close
	push r12
	syscall
	pop r12
	mov rbx, r12
	mov rax, 6  # sys_close
	syscall
	
SHELLCODE_SECTION_DELIMITER
	
sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"

