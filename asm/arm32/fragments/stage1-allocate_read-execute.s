	// allocate another new block of memory for read/execute data using mmap
	mov r7, #192             								@ SYS_MMAP2
	mov r0, #0	            								@ addr
	mov r1, #[VARIABLE:READ_EXECUTE_REGION_SIZE:VARIABLE]  	@ len
	mov r2, #0x5            								@ prot (r-x)
	mov r3, #0x22            								@ flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r4, #-1             								@ fd
	mov r5, #0              								@ offset
	swi 0x0													@ syscall
	mov r10, r0            									@ save mmap addr	- r10 = read/execute block address
