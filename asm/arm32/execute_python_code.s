// executes arbitrary Python code in an existing Python process

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

// load a pointer to the Python code
	mov r0, pc
	b load_destination_address

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"
	.balign 4

load_destination_address:
	// r0 (source) is already set to code address
	ldr r7, [pc] 	@ Set r7 to the base read/write memory address
	b copy_code_to_rw_memory

read_write_address:
	.word [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 4

copy_code_to_rw_memory:
	// Set r1 (destination) to the base read/write memory address
	mov r1, r7
	// Add 0x80 to save some space to work with before the variable-length string
	add r1, r1, #0x80
	mov r2, #[VARIABLE:pythoncode.length:VARIABLE]
	add r2, r2, #0x1	@ null terminator
	push {r7}
	bl asminject_copy_bytes
	pop {r7}

// BEGIN: call PyGILState_Ensure
// get the offset of the PyGILState_Ensure function
load_ensure_offset:
	ldr r4, [pc]
	b call_ensure

ensure_offset:
	.word [SYMBOL_ADDRESS:PyGILState_Ensure:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	.balign 4

call_ensure:
	mov r0, #0x0
	mov r1, #0x0
	push {r7}
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r4
	[INLINE:stack_align-r8-r9-post.s:INLINE]
	pop {r7}
	// store handle in read/write memory
	str r0, [r7]
// END: call PyGILState_Ensure

// BEGIN: call PyRun_SimpleStringFlags("arbitrary Python code here", NULL)
// get the offset of the PyRun_SimpleStringFlags function
	ldr r4, [pc]
	b call_run

run_offset:
	.word [SYMBOL_ADDRESS:PyRun_SimpleStringFlags:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	.balign 4

call_run:
	// load handle from read/write memory
	mov r0, r7			@ base read/write address
	add r0, r0, #0x80	@ Offset of copied string
	mov r1, #0x0			@ NULL	
	push {r7}
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r4
	[INLINE:stack_align-r8-r9-post.s:INLINE]
	pop {r7}
// END: call PyRun_SimpleStringFlags("arbitrary Python code here", NULL)
	
// BEGIN: call PyGILState_Release(handle)
// get the offset of the PyGILState_Release(handle) function
	ldr r4, [pc]
	b call_release

release_offset:
	.word [SYMBOL_ADDRESS:PyGILState_Release:IN_BINARY:.+/(lib|)python[0-9\.so]+$:SYMBOL_ADDRESS]
	.balign 4

call_release:
	// load handle from read/write memory
	ldr r0, [r7]
	push {r7}
	[INLINE:stack_align-r8-r9-pre.s:INLINE]
	blx r4
	[INLINE:stack_align-r8-r9-post.s:INLINE]
	pop {r7}

// END: call PyGILState_Release(handle)
	
	# // BEGIN: call Py_Finalize()

	# // END: call Py_Finalize()
