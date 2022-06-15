// BEGIN: swap the contents of two registers, then swap them back
push {%r0%}
push {%r1%}
push {%r2%}

// OBFUSCATION_OFF
// copy %r1% into the buffer register %r2%
mov %r2%, %r1%
// copy %r0% into %r1%
mov %r1%, %r0%
// copy buffer register %r2% into %r0%
mov %r0%, %r2%
// %r0% now contains the value that was in %r1%, and vice-versa

// do the same thing again to swap the data back
//mov %r2%, %r1%
//mov %r1%, %r0%
//mov %r0%, %r2%	
// OBFUSCATION_ON

// pop the registers from the stack to undo everything
pop {%r2%}
pop {%r1%}
pop {%r0%}
// END: swap the contents of two registers, then swap them back
