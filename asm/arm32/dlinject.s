# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libdl
# instead of the private _dl_open function that some versions of ld
# sort of exported

[FRAGMENT:asminject_libc_or_libdl_dlopen.s:FRAGMENT]

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

SHELLCODE_SECTION_DELIMITER

