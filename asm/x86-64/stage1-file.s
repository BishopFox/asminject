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

	// Open stage2 file
	mov rax, 2          # SYS_OPEN
	lea rdi, path[rip]  # path
	xor rsi, rsi        # flags (O_RDONLY)
	xor rdx, rdx        # mode
	syscall
	mov r14, rax        # save the fd for later

	// mmap it
	mov rax, 9              # SYS_MMAP
	xor rdi, rdi            # addr
	mov rsi, [VARIABLE:STAGE2_SIZE:VARIABLE]  # len
	mov rdx, 0x7            # prot (rwx)
	mov r10, 0x2            # flags (MAP_PRIVATE)
	mov r8, r14             # fd
	xor r9, r9              # off
	syscall
	mov r15, rax            # save mmap addr

	// close the file
	mov rax, 3    # SYS_CLOSE
	mov rdi, r14  # fd
	syscall

	// delete the file (not exactly necessary)
	mov rax, 87         # SYS_UNLINK
	lea rdi, path[rip]  # path
	syscall

	// jump to stage2
	jmp r15

path:
	.ascii "[VARIABLE:STAGE2_PATH:VARIABLE]\0"