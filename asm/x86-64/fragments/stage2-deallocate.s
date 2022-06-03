	// de-allocate the mmapped r/w block

	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov rax, 11              								# SYS_MUNMAP
	mov rdi, [r14 + 16]    									# start address
	mov rsi, [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]		# len
	syscall
	
	// cannot really de-allocate the r/x block because that is where this code is
