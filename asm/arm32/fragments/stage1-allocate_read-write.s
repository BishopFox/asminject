	// allocate a new block of memory for read/write data using mmap
	// I don't know why, but calling sys_mmap fails, while using SYS_MMAP2 with the same parameters succeeds
	// Thanks Andrea Sindoni! (https://www.exploit-db.com/docs/english/43906-arm-exploitation-for-iot.pdf)
	mov r7, #192             					@ SYS_MMAP2
	mov r0, #0	            					@ addr
	mov r1, #[VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]  	@ len
	mov r2, #0x3            					@ prot (rw-)
	mov r3, #0x22            					@ flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r4, #-1             					@ fd
	mov r5, #0              					@ offset
	swi 0x0										@ syscall
	mov r11, r0            						@ save mmap addr	- r11 = read/write block address
