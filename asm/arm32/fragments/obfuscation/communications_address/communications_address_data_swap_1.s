// BEGIN: swap the data at (communications address) and (communications address + 4), then swap it back
push {%r1%}
push {%r2%}
push {%r3%}
push {%r4%}
push {%r5%}
push {%r6%}
push {%r7%}
push {%r9%}

// load the communications address into %r9%
	ldr %r9%, [pc]
	b rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a

rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_rwa:
	.word [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
	.balign 4

rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a:
// first swap
// OBFUSCATION_OFF
// %r1% = value at communications address
ldr %r1%, [%r9%]
// %r2% = communications address + 4
add %r2%, %r9%, #4
// %r3% = value at communications address + 4
ldr %r3%, [%r2%]
// store %r3%
str %r3%, [%r9%]
// store %r1%
str %r1%, [%r2%] 

// second swap to put the data back where it started
// but using separate registers to make it harder to fingerprint
ldr %r5%, [%r9%]
add %r6%, %r9%, #4
ldr %r7%, [%r6%]
str %r7%, [%r9%]
str %r5%, [%r6%]
// OBFUSCATION_ON

pop {%r9%}
pop {%r7%}
pop {%r6%}
pop {%r5%}
pop {%r4%}
pop {%r3%}
pop {%r2%}
pop {%r1%}
// END: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 8 bytes between 8 and 0x800), then swap it back
