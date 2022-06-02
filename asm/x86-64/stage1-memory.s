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
	
	[READ_WRITE_ALLOCATE_OR_REUSE]
	mov rax, r11
	
	// Store the read/write block address returned by mmap
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov [r14 + 16], r11
	
	push r11
	
	// store fancy register state now rather than later
	fxsave [rax]

	// move the pushed register values into the read/write area now rather than later
	add rax, [VARIABLE:CPU_STATE_SIZE:VARIABLE]
	add rax, [VARIABLE:EXISTING_STACK_BACKUP_LOCATION_OFFSET:VARIABLE]
	mov rdi, rax
	mov rsi, [VARIABLE:STACK_POINTER_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	rep movsb
	
	[READ_EXECUTE_ALLOCATE_OR_REUSE]
	mov rax, r15
	
	// Store the read/execute block address returned by mmap
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov [r14 + 8], r15
	
	pop r11
	
	// store the sys_nanosleep timer data
	mov rbx, [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]
	mov rcx, [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]
	push rbx
	push rcx
	mov r13, rsp
	
	// overwrite communications address with [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
	// so that the Python script knows it can write stage 2 to memory
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov r12, [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
	mov [r14], r12
	
	// wait for value at communications address to be [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE] before proceeding
wait_for_script:

	mov rax, [r14]
	cmp rax, [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE]
	je launch_stage2
	
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

launch_stage2:
	
	// discard the nanosleep-related data
	pop rcx
	pop rbx
	
	// jump to stage2
	jmp r15

