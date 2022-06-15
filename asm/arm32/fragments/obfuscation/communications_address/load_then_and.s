// BEGIN: load 4 bytes from (communications address) and AND them with a random register
push {%r0%}
push {%r1%}
push {%r2%}

// load the communications address into %r0%
	ldr %r0%, [pc]
	b rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a

rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_rwa:
	.word [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	.balign 4

rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a:

// %r1% = value at read/write address
ldr %r1%, [%r0%]
and %r2%, %r1%, %r3%

pop {%r2%}
pop {%r1%}
pop {%r0%}