// BEGIN: ensure the stack is 16-byte aligned, (state in r8)
	push r8

	mov r8, rsp
	and r8, 0x8
	cmp r8, 0x8
	je align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push r8

align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	push r8
// END: ensure the stack is 16-byte aligned, (state in r8)