.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// and in part on https://github.com/lmacken/pyrasite/blob/d0c90ab38a8986527c9c1f24e222323494ab17a2/pyrasite/injector.py
cld
	// let the script know it can restore the previous data
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov r12, [VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]
	mov [r14], r12
	
[VARIABLE:SHELLCODE_SOURCE:VARIABLE]
	
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

	push rax
	mov rax, read_write_address[rip]
	fxrstor [rax]
	pop rax

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

	mov rsp, [VARIABLE:RSP:VARIABLE]
	jmp old_rip[rip]
	
old_rip:
	.quad [VARIABLE:RIP:VARIABLE]

[VARIABLE:SHELLCODE_DATA:VARIABLE]

read_write_address:
	.quad [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]

new_stack_address:
	.quad [VARIABLE:NEW_STACK_ADDRESS:VARIABLE]

read_write_address_end:
	.quad [VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]

