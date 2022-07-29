.intel_syntax noprefix
.globl _start
_start:
// Based on the stage 2 code included with dlinject.py
// and in part on https://github.com/lmacken/pyrasite/blob/d0c90ab38a8986527c9c1f24e222323494ab17a2/pyrasite/injector.py
[FRAGMENT:asminject_wait_for_script_state.s:FRAGMENT]
[FRAGMENT:asminject_set_payload_state.s:FRAGMENT]
// OBFUSCATION_ALLOCATED_MEMORY_ON
cld
	// let the script know it can restore the previous data

	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]	
	push eax
	push ebx
	push ecx
	push edx
	call asminject_set_payload_state
	pop edx
	pop ecx
	pop ebx
	pop eax
	
	// wait for the script to have restored memory, then proceed
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]
	push eax
	push ebx
	push ecx
	push edx
	call asminject_wait_for_script_state
	pop edx
	pop ecx
	pop ebx
	pop eax

execute_inner_payload:
	
	push eax
	push ebx
	push ecx
	push edx
	
	[VARIABLE:SHELLCODE_SOURCE:VARIABLE]

cleanup_and_return:

	pop edx
	pop ecx
	pop ebx
	pop eax

	// restore fancy registers
	push eax
	mov eax, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	add eax, [VARIABLE:RWR_CPU_STATE_BACKUP_OFFSET:VARIABLE]
	fxrstor [eax]
	pop eax

// let the script know that the payload is ready for cleanup
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_PAYLOAD_READY_FOR_SCRIPT_CLEANUP:VARIABLE]
	push eax
	push ebx
	push ecx
	push edx
	call asminject_set_payload_state
	pop edx
	pop ecx
	pop ebx
	pop eax

// wait for cleanup
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_SCRIPT_CLEANUP_COMPLETE:VARIABLE]
	push eax
	push ebx
	push ecx
	push edx
	call asminject_wait_for_script_state
	pop edx
	pop ecx
	pop ebx
	pop eax
	
// OBFUSCATION_ALLOCATED_MEMORY_OFF
// OBFUSCATION_COMMUNICATIONS_ADDRESS_OFF
[DEALLOCATE_MEMORY]

// OBFUSCATION_OFF
	
[STATE_RESTORE_INSTRUCTIONS]
	popf
	
	// jump back to the original instruction address
	push [VARIABLE:INSTRUCTION_POINTER:VARIABLE]
	ret
	// OBFUSCATION_ON

[VARIABLE:SHELLCODE_DATA:VARIABLE]

read_write_address:
	.long [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

existing_stack_backup_address:
	.long [VARIABLE:EXISTING_STACK_BACKUP_ADDRESS:VARIABLE]
	.balign 4

arbitrary_read_write_data_address:
	.long [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 4

read_write_address_end:
	.long [VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]
	.balign 4

[FRAGMENTS]
