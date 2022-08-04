// BEGIN: ensure the stack is 16-byte aligned, (state in r8, also uses r9)
	push {r9}
	push {r8}

	mov r8, sp
	sub r8, r8, #0x4	// one more register will be pushed onto the stack after this check
	and r9, r8, #0x8
	cmp r9, #8
	bne align_stack_push_one_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push {r8}
	push {r8}
	align_stack_push_one_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	and r9, r8, #0x4
	cmp r9, #4
	bne align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push {r8}

align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	push {r8}

// END: ensure the stack is 16-byte aligned, (state in r8, also uses r9)