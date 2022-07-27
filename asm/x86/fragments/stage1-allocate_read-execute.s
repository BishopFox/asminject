	// allocate a new block of memory for executable instructions using mmap
	mov eax, 90              								# SYS_MMAP
	//lea ebx, mmap_args_read_execute[eip]
	call stage1_allocate_rx_get_next
stage1_allocate_rx_get_next:
	# set EBX to the address of the parameters
	pop ebx
	add ebx, 6
	jmp stage1_allocate_rx_syscall

mmap_params_rx:
	.int 0x0											# start address
#	.balign 4
	.int [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]	# length
#	.balign 4
	.int 0x5											# prot (rx)
#	.balign 4
	.int 0x22											# flags (MAP_PRIVATE | MAP_ANONYMOUS)
#	.balign 4
	.int -1											# file descriptor
#	.balign 4
	.int 0x0											# start offset
#	.balign 4

stage1_allocate_rx_syscall:
	int 0x80
	mov ecx, eax            								# save mmap addr
