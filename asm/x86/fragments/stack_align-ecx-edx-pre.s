// BEGIN: ensure the stack is 16-byte aligned, (state in ecx, also uses edx)
	push edx
	push ecx

	mov ecx, esp
	// one more register will be pushed onto the stack after this check
	sub ecx, 0x4
	mov edx, ecx
	and edx, 0x8
	cmp edx, 0x8
	jne align_stack_push_one_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push ecx
	push ecx

align_stack_push_one_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	mov edx, ecx
	and edx, 0x4
	cmp edx, 0x4
	jne align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push ecx

align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	push ecx
// END: ensure the stack is 16-byte aligned, (state in ecx, also uses edx)