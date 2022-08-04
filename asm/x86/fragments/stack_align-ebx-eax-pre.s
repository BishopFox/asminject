// BEGIN: ensure the stack is 16-byte aligned, (state in ebx, also uses eax)
	push eax
	push ebx

	mov ebx, esp
	// one more register will be pushed onto the stack after this check
	sub ebx, 0x4
	mov eax, ebx
	and eax, 0x8
	cmp eax, 0x8
	jne align_stack_push_one_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push ebx
	push ebx

align_stack_push_one_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	mov eax, ebx
	and eax, 0x4
	cmp eax, 0x4
	jne align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:1]
	push ebx

align_stack_pre_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	push ebx
// END: ensure the stack is 16-byte aligned, (state in ebx, also uses eax)