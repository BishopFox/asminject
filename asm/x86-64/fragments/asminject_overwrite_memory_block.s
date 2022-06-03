// BEGIN: asminject_overwrite_memory_block
// very basic function that overwrites memory with a fixed value
// in chunks the size of the CPU registers
// rdi = start address
// rsi = stop address
// rcx = data to write to memory

asminject_overwrite_memory_block:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10

	push rax

	mov rax, rdi
asminject_overwrite_memory_block_loop:
	mov [rax], rcx
	add rax, 8
	cmp rax, rsi
	jge asminject_overwrite_memory_block_done
	jmp asminject_overwrite_memory_block_loop
	
asminject_overwrite_memory_block_done:
	pop rax
	
	leave
	ret
// END: asminject_overwrite_memory_block
