// import reusable code fragments
[FRAGMENT:asminject_libc_fopen.s:FRAGMENT]
[FRAGMENT:asminject_libc_fread.s:FRAGMENT]
[FRAGMENT:asminject_libc_fwrite.s:FRAGMENT]
[FRAGMENT:asminject_libc_fclose.s:FRAGMENT]

// load the address of the source file string into r0
	mov r0, pc
	b load_read_only_string

sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"
	.balign 4

// load the address of the read-only mode string into r1
load_read_only_string:
	mov r1, pc
	b call_asminject_libc_fopen_source

read_only_string:
	.ascii "r\0"
	.balign 4
	
call_asminject_libc_fopen_source:
	push {r11}
	bl asminject_libc_fopen
	pop {r11}

// copy the source file handle into r9 for use throughout the rest of the code
	mov r9, r0

// load the address of the destination file string into r0
	mov r0, pc
	b load_write_only_string

destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"
	.balign 4

// load the address of the write-only mode string into r1
load_write_only_string:
	mov r1, pc
	b call_asminject_libc_fopen_destination

write_only_string:
	.ascii "w\0"
	.balign 4
	
call_asminject_libc_fopen_destination:
	push {r11}
	push {r9}
	bl asminject_libc_fopen
	pop {r9}
	pop {r11}

// copy the destination file handle into r8 for use throughout the rest of the code
	mov r8, r0

// load the address of the read-write memory block
	ldr r0, [pc]
	b continue_preparing_copy

read_write_address:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

continue_preparing_copy:
	mov r7, r0		@ keep read_write address
	add r7, #0x200	@ location of fread-fwrite copy buffer

copyLoop:
	
// call fread
	mov r0, r7		@ buffer
	mov r1, #1		@ element size (1 byte)
	mov r2, #256	@ max elements to read/write (256)
	mov r3, r9		@ set file handle to source file
	push {r11}
	push {r9}
	push {r8}
	push {r7}
	bl asminject_libc_fread
	pop {r7}
	pop {r8}
	pop {r9}
	pop {r11}
	cmp r0, #0x0
	beq doneCopying
	mov r0, r7		@ buffer
	mov r1, #1		@ element size (1 byte)
	mov r2, #256	@ max elements to read/write (256)
	mov r3, r8
	push {r11}
	push {r9}
	push {r8}
	push {r7}
	bl asminject_libc_fwrite
	pop {r7}
	pop {r8}
	pop {r9}
	pop {r11}
	b copyLoop

doneCopying:

// close destination file handle using fclose()
	mov r0, r8
	push {r11}
	push {r9}
	push {r8}
	push {r7}
	bl asminject_libc_fclose
	pop {r7}
	pop {r8}
	pop {r9}
	pop {r11}

// close source file handle using fclose()
	mov r0, r9
	push {r11}
	push {r9}
	push {r8}
	push {r7}
	bl asminject_libc_fclose
	pop {r7}
	pop {r8}
	pop {r9}
	pop {r11}

SHELLCODE_SECTION_DELIMITER
