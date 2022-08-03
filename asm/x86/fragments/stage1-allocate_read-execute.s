	// allocate a new block of memory for executable instructions using mmap
	// SYS_MMAP
	mov eax, 90
	call stage1_allocate_rx_get_next
stage1_allocate_rx_get_next:
	// set EBX to the address of the parameters
	pop ebx
	add ebx, 6
	jmp stage1_allocate_rx_syscall

mmap_params_rx:
	// start address
	.int 0x0
	// length
	.int [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]
	// prot (rx)
	.int 0x5
	// flags (MAP_PRIVATE | MAP_ANONYMOUS)
	.int 0x22
	// file descriptor
	.int -1
	// start offset
	.int 0x0

stage1_allocate_rx_syscall:
	int 0x80
	// save mmap addr
	mov ecx, eax
