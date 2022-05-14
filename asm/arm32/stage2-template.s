b _start

.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// no relative offsets required, because everything is done using syscalls


// let the script know it can restore the previous data
	ldr r0, [pc]
	b store_state_ready_for_memory_restore

state_ready_for_memory_restore:
	.word [VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]
	.balign 4

store_state_ready_for_memory_restore:
	str r0, [r12]
	
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
	.word 1
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

	ldr r7, [r12]
	cmp r7, r8
	beq cleanup_and_return
	
	b wait_for_script

cleanup_and_return:
	
	[VARIABLE:SHELLCODE_SOURCE:VARIABLE]

	// de-allocate the mmapped r/w block
	mov r7, #91             					@ SYS_MUNMAP
	mov r0, r11	            					@ addr
	mov r1, #[VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]  	@ len
	swi 0x0										@ syscall
		
	// cannot really de-allocate the r/x block because that is where this code is
	
	// restore registers
	sub sp, r11, #0x4
	// currently segfaulting here:
	ldmia sp!, {r0-r12}

	// restore stack pointer
	ldr r0, [pc]
	b restoreStackPointer2
	
old_stack_pointer:
	.word [VARIABLE:RSP:VARIABLE]
	.balign 4

restoreStackPointer2:	
	
	// load the stored instruction pointer value stored right after this instruction into the program counter register
	ldr pc, [pc]

old_rip:
	.word [VARIABLE:RIP:VARIABLE]
	.balign 4

old_rip2:
	.word [VARIABLE:RIP:VARIABLE]
	.balign 4

