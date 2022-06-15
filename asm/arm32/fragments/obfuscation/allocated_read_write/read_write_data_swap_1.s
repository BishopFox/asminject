// BEGIN: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 4 bytes between 4 and about 0x400), then swap it back
push {%r0%}
push {%r1%}
push {%r2%}
push {%r3%}
push {%r4%}
push {%r5%}
push {%r6%}
push {%r7%}
push {%r8%}
push {%r9%}

// generate a pseudo-random number based on two random registers
mov %r8%, %r0%
eor %r8%, %r8%, %r1%
// limit value to 0x0 - 0xFF
and %r8%, %r8%, #0xFF
// adjust range to 0x1-0x100 and multiply by 4
add %r8%, %r8%, #1
// multiply by 4
mov %r8%, %r8%, lsl #2

// load the read/write address into %r9%
	ldr %r9%, [pc]
	b rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a

rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_rwa:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

rwds1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a:
// first swap
// OBFUSCATION_OFF
// %r1% = value at read/write address
ldr %r1%, [%r9%]
// %r2% = read/write address + pseudo-random offset
add %r2%, %r9%, %r8%
// %r3% = value at r/w address + pseudo-random offset
ldr %r3%, [%r2%]
// store %r3% (the value that was originally stored at the pseudo-random offset) to the r/w address
str %r3%, [%r9%]
// store %r1% (the value that was originally at the r/w address) to the pseudo-random offset
str %r1%, [%r2%] 

// second swap to put the data back where it started
// but using separate registers to make it harder to fingerprint
// %r5% = value at read/write address
ldr %r5%, [%r9%]
// %r6% = read/write address + pseudo-random offset
add %r6%, %r9%, %r8%
// %r7% = value at r/w address + pseudo-random offset
ldr %r7%, [%r6%]
// store %r7% (the value that was originally stored at the pseudo-random offset) to the r/w address
str %r7%, [%r9%]
// store %r5% (the value that was originally at the r/w address) to the pseudo-random offset
str %r5%, [%r6%]
// OBFUSCATION_ON

pop {%r9%}
pop {%r8%}
pop {%r7%}
pop {%r6%}
pop {%r5%}
pop {%r4%}
pop {%r3%}
pop {%r2%}
pop {%r1%}
pop {%r0%}
// END: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 8 bytes between 8 and 0x800), then swap it back
