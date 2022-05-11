	# // BEGIN: call Py_Initialize()
	# push r14
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Initialize:RELATIVEOFFSET]
	# pop r14
	# // END: call Py_Initialize()
	
	// copy the Python string to arbitrary read/write memory
	push r14
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	lea rsi, python_code[rip]
	mov rcx, [VARIABLE:pythoncode.length:VARIABLE]
	add rcx, 2												# null terminator
	rep movsb
	pop r14
	// END: copy the Python string to arbitrary read/write memory

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	push rbx
	xor rax, rax
	mov rdi, 0
	mov rsi, 0
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Ensure:RELATIVEOFFSET]
	call rbx
	mov rbx, arbitrary_read_write_data_address[rip]
	mov [rbx], rax
	pop rbx
	// END: call PyGILState_Ensure()

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	//push rbx
	mov rsi, 0
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	sub rsp, 8
	mov [rsp], rdi
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyRun_SimpleStringFlags:RELATIVEOFFSET]
	call rbx
	//pop rbx
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	// BEGIN: call PyGILState_Release(handle)
	push rbx
	mov rbx, arbitrary_read_write_data_address[rip]
	mov rax, [rbx]
	mov rdi, rax
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call PyGILState_Release(handle)
	
	# // BEGIN: call Py_Finalize()
	# push rbx
	# mov rax, 0
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Finalize:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call Py_Finalize()

BEGIN_SHELLCODE_DATA

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"

