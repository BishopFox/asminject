	// de-allocate the mmapped r/w block

	push ecx
	
	mov eax, 91              								# SYS_MUNMAP
	mov ebx, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]			# start address
	mov ecx, [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]		# len
	int 0x80
	
	pop ecx
	
	// cannot really de-allocate the r/x block because that is where this code is
