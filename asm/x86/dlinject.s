# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libdl
# instead of the private _dl_open function that some veesions of ld
# sort of exported
[FRAGMENT:asminject_libdl_dlopen.s:FRAGMENT]

	// BEGIN: call dlopen() against the specified library
	push r14
	lea edi, library_path[eip]
    call asminject_libdl_dlopen
	pop r14
	// END: call dlopen()

SHELLCODE_SECTION_DELIMITER
	
library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

