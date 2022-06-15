// BEGIN: XOR register 1 with register 2
pushfq
// OBFUSCATION_OFF
push %r0%
xor %r0%, %r1%
pop %r0%
// OBFUSCATION_ON
popfq
// END: XOR register 1 with register 2
