.globl _start
_start:
	// OBFUSCATION_OFF
[FRAGMENT:asminject_wait_for_script_state.s:FRAGMENT]
[FRAGMENT:asminject_set_payload_state.s:FRAGMENT]
[FRAGMENT:asminject_set_memory_addresses.s:FRAGMENT]
	// Save registers
	//stmdb sp!,{r0-r11}
[STATE_BACKUP_INSTRUCTIONS]
	// OBFUSCATION_ON
	
	b beginStager

beginStager:
	// allocate a new block of memory for read/write data using mmap

[READ_WRITE_ALLOCATE_OR_REUSE]
// r11 is now the address of the read/write block

.balign 16
		
	// using GCC's own =relative_reference magic doesn't work when injecting the shellcode
	// so I rolled my own using this spaghetti code trick that's straight out of the early 80s
	// the branch instruction in this code is 4 bytes long, so I stash the string immediately after it
	// then I know that it will be 4 bytes after the program counter when it hits that line, 
	// which is exactly what the pc register will be set to
	ldr r12, [pc]
	b store_rw_block_address

communication_address:
	.word [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	.balign 16

store_rw_block_address:
	mov r9, r12
	add r9, r9, #8
	str r11, [r9]

	// allocate another new block of memory for read/execute data using mmap

[READ_EXECUTE_ALLOCATE_OR_REUSE]
// r10 is now the address of the read/execute block

	// Store the read/execute block address returned by mmap
	// in the initial location
	// r0 = communications address
	// r1 = read/execute base address
	// r2 = read/write base address

	mov r0, r12
	mov r1, r10
	mov r2, r11
	bl asminject_set_memory_addresses
	
//also store the r/w and r/x block locations in the new communications address block
	mov r0, r11
	mov r1, r10
	mov r2, r11
	bl asminject_set_memory_addresses

// if the old and new communication addresses are different, then 	
// overwrite initial communications address with [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]
// and the address after that with the new communication address 
// so that the Python script knows the new location

	cmp r12, r11
	beq ready_for_stage2
	ldr r1, [pc]
	b store_state_switch_to_new_communication_address

state_switch_to_new_communication_address:
	.word [VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]
	.balign 16

store_state_switch_to_new_communication_address:
	// r0 = communications address
	// r1 = value to set
	mov r0, r12
	bl asminject_set_payload_state

// overwrite communications address at the new location with [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
// so that the Python script knows it can write stage 2 to memory
ready_for_stage2:

	ldr r1, [pc]
	b store_state_ready_for_stage_two_write

state_ready_for_stage_two_write:
	.word [VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]
	.balign 16

store_state_ready_for_stage_two_write:
	mov r0, r11
	bl asminject_set_payload_state

// wait for value at communications address to be [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE] before proceeding
// load the value that indicates shellcode written into r1
	ldr r1, [pc]
	b begin_waiting1

state_stage_two_written:
	.word [VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE]
	.balign 16

begin_waiting1:
	// r0 = communications address
	// r1 = value to wait for
	mov r0, r11
	bl asminject_wait_for_script_state

launch_stage2:

	// jump to stage2
	bx r10

[FRAGMENTS]
