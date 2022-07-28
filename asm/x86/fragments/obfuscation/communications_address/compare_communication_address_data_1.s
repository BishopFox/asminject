// BEGIN: compare the value at (communication_address) and (communication_address + 8)
push %r0%
push %r1%
push %r2%
pushf

mov %r0%, [VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]
mov %r1%, [%r0%]
add %r0%, 8
mov %r2%, [%r0%]
cmp %r1%, %r2%
je ccad1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a
cmp %r1%, %r3%

ccad1_[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]_a:

popf
pop %r2%
pop %r1%
pop %r0%
// END: compare the value at (communication_address) and (communication_address + 8)
