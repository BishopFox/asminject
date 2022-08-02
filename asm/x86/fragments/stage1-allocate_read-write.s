	// allocate a new block of memory for read/write data using mmap
	// SYS_MMAP2
	mov eax, 90
// import snarky comments about hacky ways to embed inline data in 32-bit assembly code from the ARM32 equivalent of this file
	call stage1_allocate_rw_get_next
stage1_allocate_rw_get_next:
	// set EBX to the address of the parameters
	pop ebx
	add ebx, 6
	jmp stage1_allocate_rw_syscall

mmap_params_rw:
	// start address
	.long 0x0
	// length
	.long [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]
	// prot (rw)
	.long 0x3
	// flags (MAP_PRIVATE | MAP_ANONYMOUS)
	.long 0x22
	// file descriptor
	.long -1
	// start offset
	.long 0x0

stage1_allocate_rw_syscall:
	int 0x80
	mov edx, eax
