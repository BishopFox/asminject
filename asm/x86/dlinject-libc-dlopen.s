# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libc
# instead of the private _dl_open function that some versions of ld
# export
[FRAGMENT:asminject_libc_dlopen.s:FRAGMENT]

	// BEGIN: call dlopen() against the specified library
	# set EDI to the address of the library path string
	call asminject_libdl_dlopen_library_path_get_next
asminject_libdl_dlopen_library_path_get_next:
	pop edi
	add edi, 6
	jmp asminject_libdl_dlopen_call_dlopen

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

asminject_libc_dlopen_call_dlopen:

    call asminject_libdl_dlopen
	// END: call dlopen()

SHELLCODE_SECTION_DELIMITER

