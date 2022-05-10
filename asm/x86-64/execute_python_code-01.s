	//debug
	push r14
	push rax
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 0 #from buffer
	syscall
	pop rbx
	pop rax
	pop r14
	///debug

	# // BEGIN: call Py_Initialize()
	# push r14
	# push rax
	# push rbx
	# push rbx
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Initialize:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# pop rbx
	# pop rax
	# pop r14
	# // END: call Py_Initialize()

	//debug
	push r14
	push rax
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	pop rbx
	pop rax
	pop r14
	///debug

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	push r14
	push rax
	push rbx
	xor rax, rax
	//mov rdi, 0
	//mov rsi, 0
	movabsq rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Ensure:RELATIVEOFFSET]
	call rbx
	mov r13, rax
	pop rbx
	pop rax
	pop r14
	// END: call PyGILState_Ensure()
	
	//debug
	push r14
	push r13
	push rax
	push rbx
	push rsi
	push rdi
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall
	pop rdi
	pop rsi
	pop rbx
	pop rax
	pop r13
	pop r14
	///debug
	
	// BEGIN: Allocate a block of read/write memory and copy the Python string there
	push r14
	push r13
	push r10
	push r9
	push r8
	push rax
	push rbx
	push rdx
	push rsi
	push rdi
	// allocate a new block of memory for read/write data using mmap
	mov rax, 9              								# SYS_MMAP
	xor rdi, rdi            								# start address
	mov rsi, 0x10000								  		# len
	mov rdx, 0x3            								# prot (rw)
	mov r10, 0x22           								# flags (MAP_PRIVATE | MAP_ANONYMOUS)
	mov r8, -1             									# fd
	xor r9, r9              								# offset 0
	syscall
	mov r11, rax            								# save mmap addr
	pop rdi
	pop rsi
	pop rdx
	pop rbx
	pop rax
	pop r8
	pop r9
	pop r10
	pop r13
	pop r14
	
	// copy the Python string to the new block
	push r11
	push rcx
	push rdi
	push rsi
	mov rdi, r11
	lea rsi, python_code[rip]
	mov rcx, [VARIABLE:pythoncode.length:VARIABLE]
	add rcx, 2												# null terminator
	rep movsb
	pop rsi
	pop rdi
	pop rcx
	pop r11
	// END: Allocate a block of read/write memory and copy the Python string there
	
	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rsi, 0
	mov rdi, r11
	// allocate stack variable and use it to store the address of the code
	push rdi
	sub rsp, 8
	mov [rsp], rdi

	// handle
	push r11
	//mov rax, r11
	mov rax, rsp
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyRun_SimpleStringFlags:RELATIVEOFFSET]
	call rbx
	// discard stack variable
	add rsp, 8
	pop rdi
	pop r11

	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	// END: call PyRun_SimpleString("arbitrary Python code here")

	//debug
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 5 #from buffer
	syscall
	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	///debug
	
	// de-allocate the mmapped block
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rax, 11              								# SYS_MUNMAP
	mov rdi, r11           									# start address
	mov rsi, 0x10000								  		# len
	syscall
	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	
	//debug
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 6 #from buffer
	syscall
	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	///debug
	
	// BEGIN: call PyGILState_Release(handle)
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rax, r13
	mov rdi, rax
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call rbx
	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	// END: call PyGILState_Release(handle)

	//debug
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 7 #from buffer
	syscall
	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	///debug
	
	# // BEGIN: call Py_Finalize()
	# push r14
	# push r13
	# push r11
	# push rax
	# push rbx
	# mov rax, 0
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Finalize:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# pop rax
	# pop r11
	# pop r13
	# pop r14
	# // END: call Py_Finalize()

	//debug
	push r14
	push r13
	push r11
	push rax
	push rbx
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 8 #from buffer
	syscall
	pop rbx
	pop rax
	pop r11
	pop r13
	pop r14
	///debug
	
	

BEGIN_SHELLCODE_DATA

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"

dmsg:
	.ascii "ZYXWVUTSRQPONMLKJIHG\0"
