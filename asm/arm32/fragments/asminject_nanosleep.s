// BEGIN: asminject_nanosleep
// basic wrapper around the Linux nanosleep syscall
// r0 = number of seconds to sleep
// r1 = number of nanoseconds to sleep

asminject_nanosleep:
	stmdb sp!, {r11,lr}
	add r11, sp, #0x04
	sub sp, sp, #0x20
 
	// store the sys_nanosleep timer data as temporary stack variables
	// and store a pointer to them in r0 and r1
	push {r7}
	push {r1}
	push {r0}
	
	mov r0, sp	            					@ normal wait
	mov r1, r0	            					@ wait if interrupted (same)

	[INLINE:stack_align-r8-r9-pre.s:INLINE]

	mov r7, #162             					@ sys_nanosleep
	swi 0x0										@ syscall
	
	[INLINE:stack_align-r8-r9-post.s:INLINE]

	pop {r0}
	pop {r1}
	pop {r7}

	sub sp, r11, #0x04
	ldmia sp!, {r11,pc}
// END: asminject_nanosleep
