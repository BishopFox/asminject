// BEGIN: remove extra values from the stack if any were added to align it (state in r8, also uses r9)
	pop {r8}

	and r9, r8, #0x8
	cmp r9, #8
	bne align_stack_pop_one_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop {r8}
	pop {r8}
align_stack_pop_one_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	and r9, r8, #0x4
	cmp r9, #4
	bne align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:1]
	pop {r8}

align_stack_post_[GLOBAL_SEQUENTIAL_NUMBER:0]:
	pop {r8}
	pop {r9}

// END: remove extra values from the stack if any were added to align it (state in r8, also uses r9)