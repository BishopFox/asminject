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

	# mov rax,1 # write to file
	# mov rdi,1 # stdout
	# mov rdx,1 # number of bytes
	# lea rsi, dmsg[rip] #from buffer
	# syscall
	
	// allocate a new block of memory using mmap
	mov rax, 9              # SYS_MMAP
	xor rdi, rdi            # start address
	mov rsi, [VARIABLE:STAGE2_SIZE:VARIABLE]  # len
	mov rdx, 0x7            # prot (rwx)
	mov r10, 0x22            # flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r8, -1             # fd
	xor r9, r9              # offset 0
	syscall
	mov r15, rax            # save mmap addr
	
	// store the sys_nanosleep timer data
	mov rbx, 1
	mov rcx, 1
	push rbx
	push rcx
	mov r13, rsp
	#mov varBackupData1[rip], rsp

	#mov rax,1 # write to file
	#mov rdi,1 # stdout
	#mov rdx,1 # number of bytes
	#lea rsi, dmsg[rip] + 1 #from buffer
	#syscall
	
	//mov varBackupData1[rip], [rip]
	//mov varBackupData2[rip], [rip + 8]
	
	// overwrite self at RSP address with 0x00000000
	// and RSP + 8 with the address returned by mmap
	// so that the Python script knows it can write stage 2 to memory
	//mov [rsp + 8], r15
	push r15

	#mov rax,1 # write to file
	#mov rdi,1 # stdout
	#mov rdx,1 # number of bytes
	#lea rsi, dmsg[rip] + 2 #from buffer
	#syscall

	xor rax, rax
	//mov [rip], rax
	// mov [rip] + 4, rax
	//mov [rsp], 0x0
	mov rax, 0
	push rax
	
	// wait for value at RSP to be 0x00000001 before proceeding
wait_for_script:
	#mov rax, [rsp]
	pop rax
	cmp rax, 1
	je launch_stage2
	push rax

	#mov rax,1 # write to file
	#mov rdi,1 # stdout
	#mov rdx,1 # number of bytes
	#lea rsi, dmsg[rip] + 3 #from buffer
	#syscall
	
	#mov rax,1 # write to file
	#mov rdi,1 # stdout
	#mov rdx,1 # number of bytes
	#lea rsi, newline[rip] #from buffer
	#syscall
	
	// sleep 1 second
	mov rax, 35
	#push rbx
	#push rcx
	#mov rbx, 1
	#mov rcx, 1
	#push rbx
	#push rcx
	#mov rdi, timespec_data[rip]
	#mov rdi, rsp
	#mov rdi, r13
	
	#lea rdi, varBackupData1[rip]
	mov rdi, r13

	lea rsi, [rbp]
	xor rsi, rsi
	syscall
	#pop rcx
	#pop rbx
	#pop rcx
	#pop rbx
	#pop rax
	#pop rax
	
	#push rax
	#mov rax,1 # write to file
	#mov rdi,1 # stdout
	#mov rdx,16 # number of bytes
	#lea rsi, [rsp] #from buffer
	#syscall
	#pop rax
	
	#mov rax,1 # write to file
	#mov rdi,1 # stdout
	#mov rdx,16 # number of bytes
	#lea rsi, timespec_data[rip] #from buffer
	#syscall
	
	
	jmp wait_for_script

launch_stage2:
	pop rax
	pop rcx
	pop rbx
	
	# mov rax,1 # write to file
	# mov rdi,1 # stdout
	# mov rdx,1 # number of bytes
	# lea rsi, dmsg[rip] + 4 #from buffer
	# syscall
	
	// restored backed-up data
	//mov [rip], varBackupData1[rip]
	//mov [rip + 8], varBackupData2[rip]
	pop rax
	pop rax
	
	# mov rax,1 # write to file
	# mov rdi,1 # stdout
	# mov rdx,1 # number of bytes
	# lea rsi, dmsg[rip] + 5 #from buffer
	# syscall
	
	// jump to stage2
	jmp r15

timespec_data:
	#.quad 1, 1
	#.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0xb8, 0x6b, 0x0a, 0x7f, 0x00, 0x00
	.byte 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0xe9, 0x4f, 0x34, 0x7f, 0x00, 0x00
dmsg:
	.ascii "FEDCBA987654321\0"
newline:
	.ascii "\n\0"
format_hex:
	.ascii "DEBUG: 0x%llx\n\0"
varBackupData1:
	#.space 16
	.quad 0
varBackupData2:
	#.space 16
	.quad 0