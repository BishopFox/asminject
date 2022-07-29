// BEGIN: XOR register 1 with register 2
pushf
// OBFUSCATION_OFF
push %r0%
xor %r0%, %r1%
pop %r0%
// OBFUSCATION_ON
popf
// END: XOR register 1 with register 2
