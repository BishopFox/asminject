// BEGIN: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 8 bytes between 8 and about 0x800), then swap it back
pushfq
push %r0%
push %r1%
push %r2%
push %r3%
push %r4%
push %r5%
push %r6%
push %r7%
push %r8%

// generate a pseudo-random number based on two random registers
mov %r8%, %r0%
xor %r8%, %r1%
// limit value to 0x0 - 0xFF
and %r8%, 0xFF
// adjust range to 0x1-0x100
add %r8%, 1
// multiply by 8
shl %r8%, 3

// first swap
// OBFUSCATION_OFF
movabsq %r0%, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
mov %r1%, [%r0%]
mov %r2%, %r0%
add %r2%, %r8%
mov %r3%, [%r2%]
mov [%r0%], %r3%
mov [%r2%], %r1%

// second swap to put the data back where it started
// but using separate registers to make it harder to fingerprint
movabsq %r4%, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
mov %r5%, [%r4%]
mov %r6%, %r4%
add %r6%, %r8%	
mov %r7%, [%r6%]
mov [%r4%], %r7%
mov [%r6%], %r5%
// OBFUSCATION_ON

pop %r8%
pop %r7%
pop %r6%
pop %r5%
pop %r4%
pop %r3%
pop %r2%
pop %r1%
pop %r0%
popfq
// END: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 8 bytes between 8 and 0x800), then swap it back
