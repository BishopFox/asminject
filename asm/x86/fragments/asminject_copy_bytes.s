// BEGIN: asminject_copy_bytes
// very basic byte-copying function
// edi = source address
// esi = destination address
// ecx = number of bytes to copy
// this is just a wrapper around rep movsb for this architecture
// which is kind of silly, but keeps code more consistent

asminject_copy_bytes:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	
	rep movsb
	
	leave
	ret
// END: asminject_copy_bytes
