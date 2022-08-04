// BEGIN: asminject_libc_printf
// simple wrapper for the libc printf function
// tested with libc 2.2.5 and 2.4
// Assumes the signature for printf is int printf([const] char * format, ... );
// if your libc has a different signature for printf, this code will probably fail
// rdi = format string
// rsi = first argument to include in the formatted string

asminject_libc_printf:
	push rbp
	mov rbp, rsp
	sub rsp, 0x10
	push r9
	push rcx
	push rdx
	push r8
	
	// ensure the stack is 16-byte aligned
	mov r8, rsp
	and r8, 0x8
	cmp r8, 0x8
	je asminject_libc_printf_call_inner
	push r8

asminject_libc_printf_call_inner:
	push r8
	
	mov rcx, 0
	mov rdx, 0
	mov r9, [SYMBOL_ADDRESS:^printf($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
	call r9

	pop r8
	
	// remove extra value from the stack if one was added to align it
	cmp r8, 0x8
	je asminject_libc_printf_cleanup
	pop r8

asminject_libc_printf_cleanup:
	
	pop r8
	pop rdx
	pop rcx
	pop r9
	leave
	ret
// END: asminject_libc_printf