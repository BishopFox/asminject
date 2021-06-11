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

	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] #from buffer
	syscall
	
	// allocate a block of memory using mmap
	mov rax, 9              # SYS_MMAP
	xor rdi, rdi            # addr
	mov rsi, [VARIABLE:STAGE2_SIZE:VARIABLE]  # len
	mov rdx, 0x7            # prot (rwx)
	mov r10, 0x2            # flags (MAP_PRIVATE)
	mov r8, -1             # fd
	xor r9, r9              # off
	syscall
	mov r15, rax            # save mmap addr

	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	
	// overwrite self at RIP address with 0x00000000
	// and RIP + 8 with the address returned by mmap
	// so that the Python script knows it can write stage 2 to memory
	mov [rip + 8], r15

	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall

	xor rax, rax
	mov [rip], rax
	// mov [rip] + 4, rax
	
	// wait for value at RIP to be 0x00000001 before proceeding
wait_for_script:
	mov rax, [rip]
	cmp rax, 1
	je launch_stage2

	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	
	// sleep 1 second
	mov rax, 35
	mov rdi, timespec_sec[rip]
	xor rsi, rsi        
	syscall
	
	jmp wait_for_script

launch_stage2:

	// jump to stage2
	jmp r15

timespec_sec:
	.long 1
timespec_nsec:
	.long 0
dmsg:
	.ascii "FEDCBA987654321\0"