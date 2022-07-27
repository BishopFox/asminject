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
	push ecx
	push edx
	call asminject_set_payload_state
	pop edx
	pop ecx
	
	// wait for the script to have restored memory, then proceed
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]
	push ecx
	push edx
	call asminject_wait_for_script_state
	pop edx
	pop ecx

execute_inner_payload:
	
	push ecx
	push edx
	
	[VARIABLE:SHELLCODE_SOURCE:VARIABLE]

	pop edx
	pop ecx

cleanup_and_return:

	// restore fancy registers
	push eax
	//mov eax, read_write_address[eip]
	mov eax, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	add eax, [VARIABLE:RWR_CPU_STATE_BACKUP_OFFSET:VARIABLE]
	fxrstor [eax]
	pop eax

// let the script know that the payload is ready for cleanup
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_PAYLOAD_READY_FOR_SCRIPT_CLEANUP:VARIABLE]
	push ecx
	push edx
	call asminject_set_payload_state
	pop edx
	pop ecx

// wait for cleanup
	mov esi, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	mov edi, [VARIABLE:STATE_SCRIPT_CLEANUP_COMPLETE:VARIABLE]
	push ecx
	push edx
	call asminject_wait_for_script_state
	pop edx
	pop ecx
	
// OBFUSCATION_ALLOCATED_MEMORY_OFF
// OBFUSCATION_COMMUNICATIONS_ADDRESS_OFF
[DEALLOCATE_MEMORY]

// OBFUSCATION_OFF
	
[STATE_RESTORE_INSTRUCTIONS]
	popf
	
	// jump back to the original instruction address
	//jmp old_instruction_pointer[eip]
	//jmp old_instruction_pointer
	push [VARIABLE:INSTRUCTION_POINTER:VARIABLE]
	ret
	// OBFUSCATION_ON

old_instruction_pointer:
	.word [VARIABLE:INSTRUCTION_POINTER:VARIABLE]
	.balign 4

[VARIABLE:SHELLCODE_DATA:VARIABLE]

read_write_address:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

existing_stack_backup_address:
	.word [VARIABLE:EXISTING_STACK_BACKUP_ADDRESS:VARIABLE]
	.balign 4

arbitrary_read_write_data_address:
	.word [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 4

read_write_address_end:
	.word [VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]
	.balign 4

.text

[FRAGMENTS]
