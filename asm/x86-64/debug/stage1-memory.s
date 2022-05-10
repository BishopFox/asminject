.intel_syntax noprefix
.globl _start
_start:
	// push all the things
	pushf
	push rax
	push rbx
	push rcx
	push rdx
	push rbp
	push rsi
	push rdi
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	
	//debug
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] #from buffer
	syscall
	pop rbx
	///debug
		
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
	
	// Store the read/write block address returned by mmap
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov [r14 + 16], r11
	
	push r11
	
	// store fancy register state now rather than later
	fxsave [rax]

	// move the pushed register values into the read/write area now rather than later
	add rax, [VARIABLE:CPU_STATE_SIZE:VARIABLE]
	mov rdi, rax
	mov rsi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	rep movsb	
	
	// allocate a new block of memory for executable instructions using mmap
	mov rax, 9              					# SYS_MMAP
	xor rdi, rdi            					# start address
	mov rsi, [VARIABLE:STAGE2_SIZE:VARIABLE]  	# len
	// mov rdx, 0x7            					# prot (rwx)
	mov rdx, 0x5            					# prot (rx)
	mov r10, 0x22           					# flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r8, -1             						# fd
	xor r9, r9              					# offset 0
	syscall
	mov r15, rax            					# save mmap addr
	
	// Store the read/execute block address returned by mmap
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov [r14 + 8], r15
	
	pop r11
	
	//debug
	push r15
	push r11
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	pop rbx
	pop r11
	pop r15
	///debug
	
	// store the sys_nanosleep timer data
	mov rbx, 1
	mov rcx, 1
	push rbx
	push rcx
	mov r13, rsp
	
	//debug
	push r15
	push r13
	push r11
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall
	pop rbx
	pop r11
	pop r13
	pop r15
	///debug
	
	// overwrite communications address with [VARIABLE:STATE_READY_FOR_SHELLCODE_WRITE:VARIABLE]
	// so that the Python script knows it can write stage 2 to memory
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov r12, [VARIABLE:STATE_READY_FOR_SHELLCODE_WRITE:VARIABLE]
	mov [r14], r12
	
	//debug
	push r15
	push r14
	push r13
	push r11
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	pop rbx
	pop r11
	pop r13
	pop r14
	pop r15
	///debug
	
	// wait for value at communications address to be [VARIABLE:STATE_SHELLCODE_WRITTEN:VARIABLE] before proceeding
wait_for_script:

	mov rax, [r14]
	cmp rax, [VARIABLE:STATE_SHELLCODE_WRITTEN:VARIABLE]
	je launch_stage2
	
	// sleep 1 second
	mov rax, 35

	push r15
	push r14
	push r13
	push r11
	
	mov rdi, r13

	lea rsi, [rbp]
	xor rsi, rsi
	syscall
	
	pop r11
	pop r13
	pop r14
	pop r15
	
	jmp wait_for_script

launch_stage2:
	//debug
	push r15
	push r14
	push r13
	push r11
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 4 #from buffer
	syscall
	pop rbx
	pop r11
	pop r13
	pop r14
	pop r15
	///debug
	
	// discard the nanosleep-related data
	pop rcx
	pop rbx
	
	# pop rax
	# pop rcx
	# pop rbx
	
	# pop rax
	# pop rax
	
	# //debug
	# push rbx
	# mov rax,1 # write to file
	# mov rdi,1 # stdout
	# mov rdx,1 # number of bytes
	# lea rsi, dmsg[rip] + 5 #from buffer
	# syscall
	# pop rbx
	# ///debug
	
	// jump to stage2
	jmp r15

timespec_data:
	.byte 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0xe9, 0x4f, 0x34, 0x7f, 0x00, 0x00
dmsg:
	.ascii "FEDCBA987654321\0"
newline:
	.ascii "\n\0"
format_hex:
	.ascii "DEBUG: 0x%llx\n\0"
format_string:
	.ascii "DEBUG: %s\0"
varBackupData1:
	#.space 16
	.quad 0
varBackupData2:
	#.space 16
	.quad 0