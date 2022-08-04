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

	mov rsi, r11
	mov rdi, [VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]	
	push r11
	push r14
	push r15
	call asminject_set_payload_state
	pop r15
	pop r14
	pop r11
	
	// wait for the script to have restored memory, then proceed
	mov rsi, r11
	mov rdi, [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]
	push r11
	push r14
	push r15
	call asminject_wait_for_script_state
	pop r15
	pop r14
	pop r11

execute_inner_payload:
	
	push r11
	push r14
	push r15
	
	[VARIABLE:SHELLCODE_SOURCE:VARIABLE]

cleanup_and_return:

	pop r15
	pop r14
	pop r11
	
	// restore fancy registers
	push rax
	mov rax, read_write_address[rip]
	add rax, [VARIABLE:RWR_CPU_STATE_BACKUP_OFFSET:VARIABLE]
	fxrstor [rax]
	pop rax

// let the script know that the payload is ready for cleanup
	mov rsi, r11
	mov rdi, [VARIABLE:STATE_PAYLOAD_READY_FOR_SCRIPT_CLEANUP:VARIABLE]
	push r11
	push r14
	push r15
	call asminject_set_payload_state
	pop r15
	pop r14
	pop r11

// wait for cleanup
	mov rsi, r11
	mov rdi, [VARIABLE:STATE_SCRIPT_CLEANUP_COMPLETE:VARIABLE]
	push r11
	push r14
	push r15
	call asminject_wait_for_script_state
	pop r15
	pop r14
	pop r11
	
// OBFUSCATION_ALLOCATED_MEMORY_OFF
// OBFUSCATION_COMMUNICATIONS_ADDRESS_OFF
[DEALLOCATE_MEMORY]

// OBFUSCATION_OFF
	
[STATE_RESTORE_INSTRUCTIONS]
	popfq
	
	// jump back to the original instruction address
	jmp old_instruction_pointer[rip]
	// OBFUSCATION_ON

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

arbitrary_read_write_data_address:
	.quad [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 8

read_write_address_end:
	.quad [VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]
	.balign 8

[FRAGMENTS]
