# This code will execute the specified binary shellcode (e.g. Meterpreter)
# Unless the shellcode returns after executing, the target process is likely 
# to be terminated after the shellcode executes
# On the positive side, no library calls are necessary

jmp [VARIABLE:PRECOMPILED_SHELLCODE_LABEL:VARIABLE]

[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:

# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

[VARIABLE:INLINE_SHELLCODE:VARIABLE]

jump_back_from_shellcode:

jmp [VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]