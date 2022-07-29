# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libdl
# instead of the private _dl_open function that some versions of ld
# sort of exported
[FRAGMENT:asminject_libc_or_libdl_dlopen.s:FRAGMENT]

	// BEGIN: call dlopen() against the specified library
	push r14
	lea rdi, library_path[rip]
    call asminject_libc_or_libdl_dlopen
	pop r14
	// END: call dlopen()

SHELLCODE_SECTION_DELIMITER
	
library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

