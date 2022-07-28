// BEGIN: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 4 bytes between 4 and about 0x400), then swap it back
pushf
push %r0%
push %r1%
push %r2%
push %r3%

// generate a pseudo-random number based on two random registers
mov %r3%, %r0%
xor %r3%, %r1%
// limit value to 0x0 - 0xFF
and %r3%, 0xFF
// adjust range to 0x1-0x100
add %r3%, 1
// multiply by 8
shl %r3%, 4

// first swap
// OBFUSCATION_OFF
mov %r0%, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
// load the value at the r/w address into %r1%
mov %r1%, [%r0%]
// set %r2% to the r/w address + the random offset
mov %r2%, %r0%
add %r2%, %r3%
// load the value at (the r/w address + random offset) into %r0%
mov %r0%, [%r2%]
// store the value that was originally at the r/w address into (the r/w address + random offset)
mov [%r2%], %r1%
// store the value that was originally at (the r/w address + random offset) into the r/w address
mov %r2%, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
mov [%r2%], %r0%

// second swap to put the data back where it started
mov %r0%, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
// load the value at the r/w address into %r1%
mov %r1%, [%r0%]
// set %r2% to the r/w address + the random offset
mov %r2%, %r0%
add %r2%, %r3%
// load the value at (the r/w address + random offset) into %r0%
mov %r0%, [%r2%]
// store the value that was originally at the r/w address into (the r/w address + random offset)
mov [%r2%], %r1%
// store the value that was originally at (the r/w address + random offset) into the r/w address
mov %r2%, [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
mov [%r2%], %r0%
// OBFUSCATION_ON

pop %r3%
pop %r2%
pop %r1%
pop %r0%
popf
// END: swap the data at (read/write address) and (r/w address + some pseudo-random multiple of 8 bytes between 8 and 0x800), then swap it back
