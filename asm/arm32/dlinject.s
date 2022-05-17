# Emulates the behaviour of the original dlinject.py
# Except it uses the publicly-exported dlopen() from libdl
# instead of the private _dl_open function that some versions of ld
# sort of exported

	// BEGIN: call dlopen() against the specified library
	push r14
	lea rdi, library_path[rip]
    mov rsi, 2              # mode (RTLD_NOW)
	mov rdx, [BASEADDRESS:.+/libdl-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:dlopen@@GLIBC_2.2.5:RELATIVEOFFSET]
	xor rcx, rcx
    mov r9, [BASEADDRESS:.+/libdl-[0-9\.]+.so$:BASEADDRESS] + [RELATIVEOFFSET:dlopen@@GLIBC_2.2.5:RELATIVEOFFSET]
	call r9
	pop r14
	// END: call dlopen()

SHELLCODE_SECTION_DELIMITER
	
library_path:
	.ascii "[VARIABLE:librarypath:VARIABLE]\0"

