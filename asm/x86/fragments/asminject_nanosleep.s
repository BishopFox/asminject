// BEGIN: asminject_nanosleep
// basic wrapper around the Linux nanosleep syscall
// esi = number of seconds to sleep
// edi = number of nanoseconds to sleep

asminject_nanosleep:
	push ebp
	mov ebp, esp
	sub esp, 0x20
	
	push eax
	push ebx
	push ecx
	push edx

	[INLINE:stack_align-ebx-eax-pre.s:INLINE]
	// keep 16 byte stack alignment
	// function argument count mod 4 == 0, so no extra adjustment necessary
	
	// push esi and edi onto the stack and then use the resulting stack pointer
	// as the value to pass to sys_nanosleep, to avoid having to refer to an 
	// offset or allocate memory
	push esi
	push edi
	
	// pointer to the two values just pushed onto the stack
	mov ebx, esp
	mov ecx, esp
	xor esi, esi
	
	// call sys_nanosleep
	mov eax, 162
	int 0x80
	
	pop edi
	pop esi
	
	[INLINE:stack_align-ebx-eax-post.s:INLINE]
	
	pop edx
	pop ecx
	pop ebx
	pop eax
	
	leave
	ret

// END: asminject_nanosleep
