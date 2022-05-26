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
	
	mov rax, 0
	
	# wait for the script to have restored memory, then proceed
	// wait for value at communications address to be [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE] before proceeding
	// store the sys_nanosleep timer data
	mov rbx, [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]
	mov rcx, [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]
	push rbx
	push rcx
	mov r13, rsp
	
wait_for_script:

	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov eax, [r14]
	cmp eax, [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]
	je execute_inner_payload
	
	// sleep [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE] second(s)
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

execute_inner_payload:

	pop rbx
	pop rcx
	
	[VARIABLE:SHELLCODE_SOURCE:VARIABLE]

cleanup_and_return:

	// restore fancy registers
	push rax
	mov rax, read_write_address[rip]
	fxrstor [rax]
	pop rax

	# // de-allocate the mmapped r/w block
	# movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	# mov rax, 11              								# SYS_MUNMAP
	# mov rdi, [r14 + 16]    									# start address
	# mov rsi, [VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]		# len
	# syscall
	
	# // cannot really de-allocate the r/x block because that is where this code is

[DEALLOCATE_MEMORY]

	// restore regular registers
	//mov rsp, [existing_stack_backup_address[rip]]
	
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
	
	// reset stack pointer to the original value and jump to the original instruction location
	//mov rsp, [VARIABLE:STACK_POINTER:VARIABLE]
	jmp old_instruction_pointer[rip]
	
old_instruction_pointer:
	.quad [VARIABLE:INSTRUCTION_POINTER:VARIABLE]
	.balign 8

[VARIABLE:SHELLCODE_DATA:VARIABLE]

read_write_address:
	.quad [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 8

existing_stack_backup_address:
	.quad [VARIABLE:EXISTING_STACK_BACKUP_ADDRESS:VARIABLE]
	.balign 8

new_stack_address:
	.quad [VARIABLE:NEW_STACK_ADDRESS:VARIABLE]
	.balign 8

arbitrary_read_write_data_address:
	.quad [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 8

read_write_address_end:
	.quad [VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]
	.balign 8

