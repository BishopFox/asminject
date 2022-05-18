# asminject.py - Specialized Options

## Process suspension methods

`asminject.py` supports four methods for pre/post-injection handling of the target process. Three of those methods are borrowed from the original [dlinject.py](https://github.com/DavidBuchanan314/dlinject):

* Send a suspend (SIGSTOP) signal before injection, and a resume (SIGCONT) message after injection
** This is reliable, but is somewhat intrusive. Very paranoid software might use it as an indication of tampering
* For containerized systems, using *cgroups* "freezing"
** Reliable, but not an option for non-containerized systems
* Do nothing and hope the target process doesn't step on the injected code while it's being written
** Unreliable

`asminject.py` adds a fourth option: increasing the priority of its own process and decreasing the priority of the target process. This "slow" mode (the default) generally allows it to act like [Quicksilver in _X-Men: Days of Future Past_](https://youtu.be/T9GFyZ5LREQ?t=32), making its changes to the target process at lightning speed. The target process is still running, but so slowly relative to `asminject.py` that it may as well be suspended.

```
# python3 ./asminject.py 1470158 asm/x86-64/execute_python_code.s --relative-offsets relative_offsets-python2.7.txt --relative-offsets a--var pythoncode "print('OK');" --stop-method "slow"

...omitted for brevity...
[*] Switching to super slow motion, like every late 1990s/early 2000s action film director did after seeing _The Matrix_...
[*] Current process priority for asminject.py (PID: 1470165) is 0
[*] Current CPU affinity for asminject.py (PID: 1470165) is [0, 1]
[*] Current process priority for target process (PID: 1470158) is 0
[*] Current CPU affinity for target process (PID: 1470158) is [0, 1]
[*] Setting process priority for asminject.py (PID: 1470165) to -20
[*] Setting process priority for target process (PID: 1470158) to 20
[*] Setting CPU affinity for target process (PID: 1470158) to [0, 1]
...omitted for brevity...
[*] Wrote stage 2 to '/tmp/tmppjmn1rr6'
[*] Returning to normal time...
[*] Setting process priority for asminject.py (PID: 1470165) to 0
[*] Setting process priority for target process (PID: 1470158) to 0
[*] Setting CPU affinity for target process (PID: 1470158) to [0, 1]
[+] Done!
```

## Specifying non-PIC code

Some binaries are compiled without the position-independent code build option (including, strangely enough, x86-64 builds of Python 3.x, even though 2.x for x86-64 had it enabled). This means that the offsets in the corresponding ELF are absolute instead of relative to the base address. If `asminject.py` detects a low base address (typically indicative of this condition), it will include a warning:

```
[*] '/usr/bin/python3.9' has a base address of 4194304, which is very low for position-independent code. If the exploit attempt fails, try adding --non-pic-binary "/usr/bin/python3.9" to your asminject.py options.
```

As the message indicates, this type of binary can be manually flagged using one or more `--non-pic-binary` options, which are parsed as regular expressions. e.g.:

```
# python3 ./asminject.py 1470214 asm/x86-64/execute_python_code.s --relative-offsets asminject/relative_offsets-python3.9.txt --var pythoncode "print('OK');" --non-pic-binary "/usr/bin/python3\\.[0-9]+"

...omitted for brevity...
[*] Handling '/usr/bin/python3.9' as non-PIC binary
[*] /usr/bin/python3.9: 0x0000000000000000
...omitted for brevity...
[+] Done!
```

If in doubt, the `file` command can sometimes identify whether the code is position-independent or not. In most cases, it will include the text `pie executable` for position-independent code, but just `executable` for regular code. For example, on x86-64 Linux, Python 2.7 is position-independent, but Python 3.9 is not:

```
# file /usr/bin/python2.7

/usr/bin/python2.7: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=2e424007a240d090ed9d3965398d9d79298f0a37, for GNU/Linux 3.2.0, stripped

# file /usr/bin/python3.9

/usr/bin/python3.9: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=18e54a049c2ca8e609eaea044df101effead3b23, for GNU/Linux 3.2.0, stripped
```

On the other hand, on ARM32 Linux running on a Raspberry Pi, neither Python 2.7 and 3.7 are position-independent, but `libc` is.

```
# file /usr/bin/python2.7

/usr/bin/python2.7: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=2ab8406bc7cc1bef1e255e4e20a5b1f15758cacf, stripped

# file /usr/bin/python3.7

/usr/bin/python3.7: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=fd15ce8be633e2667c780b770eec5ecf01641017, stripped
```

However, just to be confusing, x86-64 Linux describes `libc` as a "shared object", without indicating that it's position-independent:

```
# file /usr/lib/x86_64-linux-gnu/libc-2.33.so

/usr/lib/x86_64-linux-gnu/libc-2.33.so: ELF 64-bit LSB shared object, x86-64, version 1 (GNU/Linux), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=d0bea38a0bc75e09b36838f9b6680de85ba65f15, for GNU/Linux 3.2.0, stripped
```

...but ARM2 Linux describes `libc` as a "pie executable"

```
# file /lib/arm-linux-gnueabihf/libc-2.28.so

/lib/arm-linux-gnueabihf/libc-2.28.so: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, BuildID[sha1]=efdd27c16f5283e5c53dcbd1bbc3ef136e312d1b, for GNU/Linux 3.2.0, stripped
```

If you want to be sure, run a copy of the target in `gdb`, and check whether the offsets of known functions are relative to the base address or not. For example, the following shell output indicates that the base address for `/usr/bin/python2.7` is 0x00010000, and the list of offsets indicates that the `PyGILState_Ensure` function is as 0x0018b428:

```
# cat /proc/14629/maps

00010000-0028f000 r-xp 00000000 b3:07 523346     /usr/bin/python2.7
...omitted for brevity...

grep PyGILState_Ensure relative_offsets-python2.7.txt

0018b428 PyGILState_Ensure
```

If `/usr/bin/python2.7` was position-independent, then the `PyGILState_Ensure` function would be at address 0x0019b428. In `gdb`, disassembling at this address produces what seems at least superficially like valid code:

```
(gdb) disassemble 0x19B428, 0x0019b450
Dump of assembler code from 0x19b428 to 0x19b450:
   0x0019b428:	sub	r4, r4, #1
   0x0019b42c:	cmn	r4, #1
   0x0019b430:	orr	r6, r6, r10, lsl r11
   0x0019b434:	bne	0x19b418
   0x0019b438:	and	r9, r9, #31
   0x0019b43c:	mov	r7, #1
   0x0019b440:	sub	r10, r3, #-1073741823	; 0xc0000001
   0x0019b444:	orr	r11, r6, r7, lsl r9
=> 0x0019b448:	ldr	r10, [r1, r10, lsl #2]
   0x0019b44c:	mov	r4, #0
```

However, if `/usr/bin/python2.7` was *not* position-independent, then the `PyGILState_Ensure` function would be at address 0x0018b428 instead, and disassembling there reveals labels for that function:

```
(gdb) disassemble 0x18b428, 0x1b8450
Dump of assembler code from 0x18b428 to 0x1b8450:
   0x0018b428 <PyGILState_Ensure+0>:	ldr	r3, [pc, #140]	; 0x18b4bc <PyGILState_Ensure+148>
   0x0018b42c <PyGILState_Ensure+4>:	push	{r4, r5, r6, lr}
   0x0018b430 <PyGILState_Ensure+8>:	ldr	r0, [r3]
   0x0018b434 <PyGILState_Ensure+12>:	bl	0x14853c <PyThread_get_key_value>
   0x0018b438 <PyGILState_Ensure+16>:	subs	r4, r0, #0
   0x0018b43c <PyGILState_Ensure+20>:	beq	0x18b47c <PyGILState_Ensure+84>
   0x0018b440 <PyGILState_Ensure+24>:	ldr	r1, [pc, #120]	; 0x18b4c0 <PyGILState_Ensure+152>
```

In this case (Python 2.7 on ARM32 Linux), the binary was *not* position-independent, and using `asminject.py` successfully required adding the option `--non-pic-binary "/usr/bin/python.*"`.

## Multi-architecture support

`asminject.py` currently supports both x86-64 and ARM32 payloads. Add the `--arch arm32` option to use ARM32. The examples for that architecture in the documentation were executed on a Raspberry Pi.