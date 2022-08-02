# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libdl
# instead of the private _dl_open function that some versions of ld
# sort of exported
[FRAGMENT:asminject_ld_dl_open.s:FRAGMENT]

	// BEGIN: call _dl_open() against the specified library
	push r14
	lea rdi, library_path[rip]
    call asminject_ld_dl_open
	pop r14
	// END: call _dl_open()

SHELLCODE_SECTION_DELIMITER
	
library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

