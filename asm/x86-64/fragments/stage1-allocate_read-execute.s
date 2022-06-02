	// allocate a new block of memory for executable instructions using mmap
	mov rax, 9              								# SYS_MMAP
	xor rdi, rdi            								# start address
	mov rsi, [VARIABLE:READ_EXECUTE_REGION_SIZE:VARIABLE]  	# len
	// mov rdx, 0x7            								# prot (rwx)
	mov rdx, 0x5            								# prot (rx)
	mov r10, 0x22           								# flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r8, -1             									# fd
	xor r9, r9              								# offset 0
	syscall
	mov r15, rax            								# save mmap addr
