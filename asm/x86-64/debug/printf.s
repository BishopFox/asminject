.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// and in part on https://github.com/lmacken/pyrasite/blob/d0c90ab38a8986527c9c1f24e222323494ab17a2/pyrasite/injector.py
// relative offsets for the following libraries required:
//		libc
//			Tested specifically with libc-[0-9\.]+.so
cld
	# push rax
	# mov rax, [read_write_address[rip]]
	# fxsave [rax]
	# //fxsave [read_write_address[rip]]
	# pop rax
	
	//debug
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] #from buffer
	syscall
	pop rbx
	///debug
	
	# // move pushed regs to our new stack
	# //lea rdi, [new_stack_address[rip]]
	# mov rdi, [new_stack_address[rip]]
	# mov rsi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	# mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	# rep movsb

	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	pop r14
	///debug

	// let the script know it can restore the previous data
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov r12, [VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]
	mov [r14], r12

	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall
	pop r14
	///debug
	
	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	pop r14
	///debug
	
	// BEGIN: example of calling a LIBC function from the asm code using template values
	push r14
	push rax
	push rbx
	lea rsi, dmsg[rip]
	lea rdi, format_string[rip]
	xor rax, rax
	xor eax, eax
	movabsq rbx, [BASEADDRESS:.+/libc-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:printf@@GLIBC_2.2.5:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop rax
	pop r14
	// END: example of calling a LIBC function from the asm code using template values
	
	//debug
	push r14
	push r15
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 4 #from buffer
	syscall
	pop rbx
	pop r15
	pop r14
	///debug
	
	mov rax, 0
	
	# wait for the script to have restored memory, then restore all of the registers
	# and jump back to the original instruction
	// wait for value at communications address to be [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE] before proceeding
	// store the sys_nanosleep timer data
	mov rbx, 1
	mov rcx, 1
	push rbx
	push rcx
	mov r13, rsp
	
wait_for_script:

	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov eax, [r14]
	cmp eax, [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]
	je cleanup_and_return
	
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

cleanup_and_return:

	pop rbx
	pop rcx

	//debug
	push r14
	push r15
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 5 #from buffer
	syscall
	pop rbx
	pop r15
	pop r14
	///debug

	push rax
	mov rax, read_write_address[rip]
	//lea rax, [read_write_address[rip]]
	//push rax
	//mov rax, 0
	fxrstor [rax]
	//fxrstor [rsp]
	//pop rax
	//fxrstor rax
	//fxrstor [read_write_address[rip]]
	pop rax

	//lea rsp, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]
	//lea rsp, [new_stack_address[rip]]
	mov rsp, [new_stack_address[rip]]
	
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
	
	# //debug
	# pushf
	# push rax
	# push rbx
	# push rcx
	# push rdx
	# push rbp
	# push rsi
	# push rdi
	# push r8
	# push r9
	# push r10
	# push r11
	# push r12
	# push r13
	# push r14
	# push r15
	# mov rax,1 # write to file
	# mov rdi,1 # stdout
	# mov rdx,1 # number of bytes
	# lea rsi, dmsg[rip] + 6 #from buffer
	# syscall
	# pop r15
	# pop r14
	# pop r13
	# pop r12
	# pop r11
	# pop r10
	# pop r9
	# pop r8
	# pop rdi
	# pop rsi
	# pop rbp
	# pop rdx
	# pop rcx
	# pop rbx
	# pop rax
	# popf
	# ///debug

	mov rsp, [VARIABLE:RSP:VARIABLE]
	jmp old_rip[rip]
	
old_rip:
	.quad [VARIABLE:RIP:VARIABLE]

format_string:
	.ascii "DEBUG: %s\0"

dmsg:
	.ascii "ZYXWVUTSRQPONMLKJIHG\0"

read_write_address:
	.quad [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]

new_stack_address:
	.quad [VARIABLE:NEW_STACK_ADDRESS:VARIABLE]

read_write_address_end:
	.quad [VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]

