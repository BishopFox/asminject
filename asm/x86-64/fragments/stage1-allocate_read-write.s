	// allocate a new block of memory for read/write data using mmap
	mov rax, 9              								# SYS_MMAP
	xor rdi, rdi            								# start address
	mov rsi, [VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]  	# len
	mov rdx, 0x3            								# prot (rw)
	mov r10, 0x22           								# flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r8, -1             									# fd
	xor r9, r9              								# offset 0
	syscall
	mov r11, rax            								# save mmap addr
