# Emulates the behaviour of the original dlinject.py
# using the _dl_open function that some versions of ld export
[FRAGMENT:asminject_ld_dl_open.s:FRAGMENT]

	// BEGIN: call _dl_open() against the specified library
	# set ESI to the address of the library path string
	call dlinject_ld_library_path_get_next
dlinject_ld_library_path_get_next:
	pop esi
	add esi, 6
	jmp dlinject_ld_call_dl_open

library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

dlinject_ld_call_dl_open:

	// copy the path string into read/write memory
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	mov ecx, [VARIABLE:librarypath.length:VARIABLE]
	add ecx, 2												# null terminator
	rep movsb
	// make sure EDI is set to the location of the copied string
	mov edi, [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]

	push eax
	push ebx
	push ecx
	push edx
    call asminject_ld_dl_open
	pop edx
	pop ecx
	pop ebx
	pop eax
	// END: call _dl_open()

SHELLCODE_SECTION_DELIMITER

