// BEGIN: remove extra value from the stack if one was added to align it (state in ecx, also uses edx)
	pop ecx

	mov edx, ecx
	and edx, 0x8
	cmp edx, 0x8
	jne align_stack_pop_one_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop ecx
	pop ecx

align_stack_pop_one_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	mov edx, ecx
	and edx, 0x4
	cmp edx, 0x4
	jne align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop ecx

align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	pop ecx
	pop edx
// END: remove extra value from the stack if one was added to align it (state in ecx, also uses edx)