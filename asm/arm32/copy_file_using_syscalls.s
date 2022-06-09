// copy a file using only Linux syscalls

	mov r8, pc
	b openSourceFile

sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"
	.balign 8

openSourceFile:
	// Open source file
	mov r7, #5			@ SYS_OPEN
	mov r0, r8
	mov r1, #0       	@ flags (O_RDONLY)
	mov r2, #0        	@ mode
	swi 0x0				@ syscall
	mov r5, r0        	@ source fd
	
	mov r12, pc
	b openDestFile
destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"
	.balign 8
	
openDestFile:
	// Open destination file
	mov r7, #5			@ SYS_OPEN
	mov r0, r12
	mov r1, #0x42       @ flags (O_RDWR | O_CREAT)
	mov r2, #1			@ mode:  make destination world-writable
	mov r2, r2, lsl #8	@ Can't mov 0777 / 0x1ff as an immediate into a register on ARM
	add r2, r2, #0xff  
	swi 0x0				@ syscall
	mov r10, r0        	@ dest fd
	
	.ltorg
//	b beginCopy

// beginCopy:
	// create a stack variable to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	sub sp,sp,#0x10
	mov r9, #0
	str r9, [sp, #0x8]
	mov r9, sp

copyByteLoop:
	
	// read a single byte at a time to avoid more complex logic
	mov r7, #3			@ SYS_READ
	mov r0, r5			@ fd
	mov r1, r9       	@ buffer
	mov r2, #1        	@ number of bytes to read
	swi 0x0				@ syscall

	// if no char was read (usually end-of-file), processing is complete
	cmp r0, #1        	@ result of read operation
	blt doneCopying
		
	// write the byte to the destination file
	mov r7, #4			@ SYS_WRITE   
	mov r0, r10			@ fd
	mov r1, r9       	@ buffer
	mov r2, #1        	@ number of bytes to write
	swi 0x0				@ syscall

	b copyByteLoop

doneCopying:
	
	// discard the buffer stack variable
	add sp,sp,#0x10

	// close file handles
	mov r7, #6			@ SYS_CLOSE
	mov r0, r5  		@ fd
	swi 0x0				@ syscall
	
	mov r7, #6			@ SYS_CLOSE
	mov r0, r10			@ fd
	swi 0x0				@ syscall

