// BEGIN: swap the contents of two registers, then swap them back
pushfq
push %r0%
push %r1%
push %r2%

// OBFUSCATION_OFF
mov %r2%, %r1%
mov %r1%, %r0%
mov %r0%, %r2%
mov %r2%, %r1%
mov %r1%, %r0%
mov %r0%, %r2%	
// OBFUSCATION_ON

pop %r2%
pop %r1%
pop %r0%
popfq
// END: swap the contents of two registers, then swap them back
