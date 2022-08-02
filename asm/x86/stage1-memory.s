.intel_syntax noprefix
.globl _start
_start:
	// OBFUSCATION_OFF
[FRAGMENT:asminject_wait_for_script_state.s:FRAGMENT]
[FRAGMENT:asminject_set_payload_state.s:FRAGMENT]
[FRAGMENT:asminject_set_memory_addresses.s:FRAGMENT]
	// push all the things
	pushf
[STATE_BACKUP_INSTRUCTIONS]
	// OBFUSCATION_ON
	
	[READ_WRITE_ALLOCATE_OR_REUSE]
	// edx is now the address of the read/write block
	mov eax, edx
	
	push edx
	
	// store fancy register state now rather than later
	add eax, [VARIABLE:RWR_CPU_STATE_BACKUP_OFFSET:VARIABLE]
	fxsave [eax]
	
	[READ_EXECUTE_ALLOCATE_OR_REUSE]
	// ecx is now the address of the read/execute block
	
	pop edx

store_addresses:

	// store block addresses at original communications address
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, ecx
	mov ebx, edx
	push edx
	push ecx
	call asminject_set_memory_addresses
	pop ecx
	pop edx
	
	// Also store the block addresses in the new communication address offset
	mov esi, edx
	mov edi, ecx
	push edx
	push ecx
	call asminject_set_memory_addresses
	pop ecx
	pop edx

	// if the old and new communication addresses are not the same, then 
	// overwrite initial communications address with [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]
	// and the address after that with the new communication address 
	// so that the Python script knows the new location
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	cmp edx, esi
	je ready_for_stage_2
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]	
	call asminject_set_payload_state

ready_for_stage_2:

	// overwrite communications address with [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
	// so that the Python script knows it can write stage 2 to memory
	mov esi, edx
	mov edi, [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]	
	push edx
	push ecx
	call asminject_set_payload_state
	pop ecx
	pop edx
	
	// wait for script to signal [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE] before proceeding
	mov esi, edx
	mov edi, [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE]
	push edx
	push ecx
	call asminject_wait_for_script_state
	pop ecx
	pop edx
	
launch_stage2:
	
	// jump to stage2
	jmp ecx

[FRAGMENTS]
