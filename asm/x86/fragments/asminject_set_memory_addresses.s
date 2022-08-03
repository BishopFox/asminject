// BEGIN: asminject_set_memory_addresses
// set a payload state value
// esi = communications address
// edi = read/execute base address
// ebx = read/write base address

asminject_set_memory_addresses:
	push ebp
	mov ebp, esp
	sub esp, 0x20
	
	// communications address
	push eax
	
	mov eax, esi
	add eax, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_EXECUTE_BASE_ADDRESS:VARIABLE]
	mov [eax], edi
	
	mov eax, esi
	add eax, [VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_WRITE_BASE_ADDRESS:VARIABLE]
	mov [eax], ebx
	
	pop eax
	
	leave
	ret
	
// END: asminject_set_memory_addresses
