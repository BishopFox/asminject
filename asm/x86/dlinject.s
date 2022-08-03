# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libdl
# instead of the _dl_open function that some versions of ld
# export
[FRAGMENT:asminject_libc_or_libdl_dlopen.s:FRAGMENT]

	// BEGIN: call dlopen() against the specified library
	# set EDI to the address of the library path string
	call dlinject_library_path_get_next
dlinject_library_path_get_next:
	pop edi
	add edi, 6
	jmp dlinject_call_dlopen

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

dlinject_call_dlopen:

    call asminject_libc_or_libdl_dlopen
	// END: call dlopen()

SHELLCODE_SECTION_DELIMITER

