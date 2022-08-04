// BEGIN: remove extra value from the stack if one was added to align it (state in r8)
	pop r8

	cmp r8, 0x8
	je align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop r8

align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	pop r8
// END: remove extra value from the stack if one was added to align it (state in r8)