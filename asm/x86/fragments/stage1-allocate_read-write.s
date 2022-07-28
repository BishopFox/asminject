	// allocate a new block of memory for read/write data using mmap
	mov eax, 90              								# SYS_MMAP2
	//lea ebx, mmap_args_read_write[eip]
# import snarky comments about hacky ways to embed inline data in 32-bit assembly code from the ARM32 equivalent of this file
	call stage1_allocate_rw_get_next
stage1_allocate_rw_get_next:
	# set EBX to the address of the parameters
	pop ebx
	add ebx, 6
	jmp stage1_allocate_rw_syscall

mmap_params_rw:
	.long 0x0											# start address
#	.balign 4
	.long [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]	# length
#	.balign 4
	.long 0x3											# prot (rw)
#	.balign 4
	.long 0x22											# flags (MAP_PRIVATE | MAP_ANONYMOUS)
#	.balign 4
	.long -1											# file descriptor
#	.balign 4
	.long 0x0											# start offset
#	.balign 4

stage1_allocate_rw_syscall:
	int 0x80
	mov edx, eax
