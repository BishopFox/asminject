// not currently used
// overwrite the mmapped r/w block
	jmp stage2_overwrite_rw_block

[FRAGMENT:asminject_overwrite_memory_block.s:FRAGMENT]
	
stage2_overwrite_rw_block:
// rdi = start address
// rsi = stop address
// rcx = data to write to memory
	push rdi
	push rsi
	push rcx
	
	mov rdi, read_write_address[rip]
	mov rsi, read_write_address[rip]
	add rsi, [VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]
	mov rcx, clear_payload_memory_value[rip]
	call asminject_overwrite_memory_block

	pop rcx
	pop rsi
	pop rdi
	
