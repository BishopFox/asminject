// BEGIN: remove extra value from the stack if one was added to align it (state in ebx, also uses eax)
	pop ebx

	mov eax, ebx
	and eax, 0x8
	cmp eax, 0x8
	jne align_stack_pop_one_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop ebx
	pop ebx

align_stack_pop_one_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	mov eax, ebx
	and eax, 0x4
	cmp eax, 0x4
	jne align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop ebx

align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	pop ebx
	pop eax
// END: remove extra value from the stack if one was added to align it (state in ebx, also uses eax)