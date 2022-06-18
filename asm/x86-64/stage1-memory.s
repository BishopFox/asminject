.intel_syntax noprefix
.globl _start
_start:
	// OBFUSCATION_OFF
[FRAGMENT:asminject_wait_for_script_state.s:FRAGMENT]
[FRAGMENT:asminject_set_payload_state.s:FRAGMENT]
[FRAGMENT:asminject_set_memory_addresses.s:FRAGMENT]
	// push all the things
	pushfq
[STATE_BACKUP_INSTRUCTIONS]
	// OBFUSCATION_ON
	
	[READ_WRITE_ALLOCATE_OR_REUSE]
	mov rax, r11
	
	push r11
	
	// store fancy register state now rather than later
	add rax, [VARIABLE:RWR_CPU_STATE_BACKUP_OFFSET:VARIABLE]
	fxsave [rax]
	
	[READ_EXECUTE_ALLOCATE_OR_REUSE]
	
	pop r11

	// if the old and new communication addresses are not the same, then 
	// overwrite initial communications address with [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]
	// and the address after that with the new communication address 
	// so that the Python script knows the new location
	movabsq r14, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	cmp r11, r14
	je store_addresses
	mov rsi, r14
	mov rdi, [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]	
	call asminject_set_payload_state
store_addresses:

	// store values at original communications address
	mov rsi, r14
	mov rdi, r15
	mov rcx, r11
	push r11
	push r14
	push r15
	call asminject_set_memory_addresses
	pop r15
	pop r14
	pop r11
	
	// Also store the block addresses in the new communication address offset
	mov rsi, r11
	mov rdi, r15
	mov rcx, r11
	push r11
	push r14
	push r15
	call asminject_set_memory_addresses
	pop r15
	pop r14
	pop r11
	
	// overwrite communications address with [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
	// so that the Python script knows it can write stage 2 to memory
	mov rsi, r11
	mov rdi, [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]	
	push r11
	push r14
	push r15
	call asminject_set_payload_state
	pop r15
	pop r14
	pop r11
	
	// wait for script to signal [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE] before proceeding
	mov rsi, r11
	mov rdi, [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE]
	push r11
	push r14
	push r15
	call asminject_wait_for_script_state
	pop r15
	pop r14
	pop r11
	
launch_stage2:
	
	// jump to stage2
	jmp r15

[FRAGMENTS]
