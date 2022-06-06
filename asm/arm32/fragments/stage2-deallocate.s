	// de-allocate the mmapped r/w block
	mov r7, #91             					@ SYS_MUNMAP
	mov r0, r11	            					@ addr
	mov r1, #[VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]  	@ len
	swi 0x0										@ syscall
		
	// cannot really de-allocate the r/x block because that is where this code is
	