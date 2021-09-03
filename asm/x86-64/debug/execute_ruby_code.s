.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// and in part on https://github.com/lmacken/pyrasite/blob/d0c90ab38a8986527c9c1f24e222323494ab17a2/pyrasite/injector.py
// relative offsets for the following libraries required:
//		libruby (same version as target process)
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

	# // BEGIN: call ruby_sysinit
	# push rbx
	# lea rax, ruby_argv[rip]	# fake argv data
	# lea rdx, ruby_argc[rip]	# fake argc data
	# mov rsi, rdx
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_sysinit:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_sysinit
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	///debug
	
	# // BEGIN: call ruby_init_stack
	# push rbx
	# lea rax, [RBP - 8]
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_stack:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init_stack
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 4 #from buffer
	syscall
	///debug
	
	# // BEGIN: call ruby_init
	# push rbx
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 5 #from buffer
	syscall
	///debug
	
	# // BEGIN: call ruby_init_loadpath
	# push rbx
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_loadpath:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init_loadpath
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 6 #from buffer
	syscall
	///debug
	
	# // BEGIN: call rb_require
	# push rbx
	# lea rdi, ruby_require[rip]
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_require:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call rb_require
	
	// BEGIN: call rb_eval_string
	push rbx
	lea rdi, ruby_code[rip]
	mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:rb_eval_string:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call rb_eval_string
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 8 #from buffer
	syscall
	///debug
	
	# // BEGIN: call ruby_cleanup
	# push rbx
	# mov rdi, 0
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_cleanup:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_cleanup
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 9 #from buffer
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

ruby_require:
	.ascii "[VARIABLE:rubyrequire:VARIABLE]\0"

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"

ruby_argv:
	.ascii "[VARIABLE:rubyargv:VARIABLE]\0"
	
ruby_argc:
	.byte 1

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


