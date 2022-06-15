// BEGIN: fake function with call
push {%r0%}
push {%r1%}
push {%r2%}
push {%r3%}

// jump to the fake referencing code
b ffwc1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a

// fake function, may be populated by other obfuscation code
ffwc1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_func:
	//OBFUSCATION_OFF
	stmdb sp!, {%r3%,lr}
	add %r3%, sp, #0x04
	sub sp, sp, #0x20
	//OBFUSCATION_ON
	add %r0%, %r1%, %r2%
	//OBFUSCATION_OFF
	sub sp, %r3%, #0x04
	ldmia sp!, {%r3%,pc}
	//OBFUSCATION_ON
	
ffwc1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a:
	mov %r0%, %r1%
	bl ffwc1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_func

// pop the registers from the stack to undo everything
pop {%r3%}
pop {%r2%}
pop {%r1%}
pop {%r0%}
// END: fake function with call
