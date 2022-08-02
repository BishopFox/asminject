// BEGIN: asminject_libc_printf
// simple wrapper for the libc printf function
// tested with libc 
// Assumes the signature for printf is int printf([const] char * format, ... );
// if your libc has a different signature for printf, this code will probably fail
// edi = format string
// esi = first argument to include in the formatted string

asminject_libc_printf:
	push ebp
	mov ebp, esp
	sub esp, 0x10
	push eax
	push ebx
	push ecx
	push edx
	
	push esi
	push edi
	mov ebx, esp

	mov edx, [FUNCTION_ADDRESS:^printf($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:FUNCTION_ADDRESS]
	call edx

	pop edi
	pop esi

	pop edx
	pop ecx
	pop ebx
	pop eax
	leave
	ret
// END: asminject_libc_printf