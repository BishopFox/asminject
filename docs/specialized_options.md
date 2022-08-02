# asminject.py - Specialized Options

* [Multi-architecture support](#multi-architecture-support)
* [Process suspension methods](#process-suspension-methods)
* [Specifying non-PIC code](#specifying-non-pic-code)
* [Specifying memory allocation size](#specifying-memory-allocation-size)
* [Memory reuse](#memory-reuse)
* [Anti-forensics](#anti-forensics)
* [Restoring more of the target process's memory](#restoring-more-of-the-target-processs-memory)
* [Payload obfuscation](#payload-obfuscation)
* [Debugging/troubleshooting options](#debuggingtroubleshooting-options)

## Multi-architecture support

`asminject.py` currently supports x86-64 (64-bit AMD/Intel), x86 (32-bit Intel/AMD), and ARM32 payloads. As of version 0.37, it will attempt to autodetect the architecture. If the automatic detection fails, or you want to override it for some reason, you can explicitly specify the architecture with the `--arch` option, e.g. `--arch arm32`.

## Process suspension methods

`asminject.py` supports four methods for pre/post-injection handling of the target process. Three of those methods are borrowed from the original [dlinject.py](https://github.com/DavidBuchanan314/dlinject):

* Send a suspend (SIGSTOP) signal before injection, and a resume (SIGCONT) message after injection
  * This is reliable, but is somewhat intrusive. Very paranoid software might use it as an indication of tampering
* For containerized systems, using *cgroups* "freezing"
  * Reliable, but not an option for non-containerized systems
* Do nothing and hope the target process doesn't step on the injected code while it's being written
  * Unreliable

`asminject.py` adds a fourth option: increasing the priority of its own process and decreasing the priority of the target process. This "slow" mode (the default) generally allows it to act like [Quicksilver in _X-Men: Days of Future Past_](https://youtu.be/T9GFyZ5LREQ?t=32), making its changes to the target process at lightning speed. The target process is still running, but so slowly relative to `asminject.py` that it may as well be suspended.

The `slow` method has worked so well in testing that it's the default in current versions of `asminject.py`.

```
# python3 ./asminject.py 1470158 execute_python_code.s \
    --relative-offsets-from-binaries \
    --var pythoncode "print('OK');" \

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
[*] '/usr/bin/python3.9' has a base address of 4194304, which is very low 
    for position-independent code. If the exploit attempt fails, try adding 
	--non-pic-binary "/usr/bin/python3.9" to your asminject.py options.
```

As the message indicates, this type of binary can be manually flagged using one or more `--non-pic-binary` options, which are parsed as regular expressions. e.g.:

```
# python3 ./asminject.py 1470214 execute_python_code.s \
    --relative-offsets-from-binaries \
	--var pythoncode "print('OK');" \
	--non-pic-binary "/usr/bin/python3\\.[0-9]+"

...omitted for brevity...
[*] Handling '/usr/bin/python3.9' as non-PIC binary
[*] /usr/bin/python3.9: 0x0000000000000000
...omitted for brevity...
[+] Done!
```

If in doubt, the `file` command can sometimes identify whether the code is position-independent or not. In most cases, it will include the text `pie executable` for position-independent code, but just `executable` for regular code. For example, on x86-64 Linux, Python 2.7 is position-independent, but Python 3.9 is not:

```
# file /usr/bin/python2.7

/usr/bin/python2.7: ELF 64-bit LSB pie executable, x86-64 [...]

# file /usr/bin/python3.9

/usr/bin/python3.9: ELF 64-bit LSB executable, x86-64 [...]
```

On the other hand, on ARM32 Linux running on a Raspberry Pi, neither Python 2.7 and 3.7 are position-independent, but `libc` is.

```
# file /usr/bin/python2.7

/usr/bin/python2.7: ELF 32-bit LSB executable, ARM [...]

# file /usr/bin/python3.7

/usr/bin/python3.7: ELF 32-bit LSB executable, ARM [...]
```

However, just to be confusing, x86-64 Linux describes `libc` as a "shared object", without indicating that it's position-independent:

```
# file /usr/lib/x86_64-linux-gnu/libc-2.33.so

/usr/lib/x86_64-linux-gnu/libc-2.33.so: ELF 64-bit LSB shared object, x86-64 [...]
```

...but ARM32 Linux describes `libc` as a "pie executable"

```
# file /lib/arm-linux-gnueabihf/libc-2.28.so

/lib/arm-linux-gnueabihf/libc-2.28.so: ELF 32-bit LSB pie executable, ARM [...]
```

If you want to be sure, run a copy of the target in `gdb`, and check whether the offsets of known functions are relative to the base address or not. For example, the following shell output indicates that the base address for `/usr/bin/python2.7` is 0x00010000, and the list of offsets indicates that the `PyGILState_Ensure` function is as 0x0018b428:

```
# cat /proc/14629/maps

00010000-0028f000 r-xp [...] /usr/bin/python2.7
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

## Specifying memory allocation size

By default, `asminject.py` selects random amounts of memory to allocate for its read/execute and read/write blocks. These blocks should be more than large enough for all of the payloads included with the tool. If you are using custom payloads that require more space, or wish to control the values for reproducibility, the `--use-read-execute-size` `--use-read-write-size` options can be used to select fixed sizes. For example:

```
# python3 ./asminject.py 2684562 execute_python_code.s \
    --relative-offsets-from-binaries \
	--non-pic-binary "/usr/bin/python3\\.[0-9]+" \
	--var pythoncode "print('injected python code');" \
	--do-not-deallocate \
	--use-read-execute-size 0x100000 \
	--use-read-write-size 0x100000
```

## Memory reuse

`asminject.py` needs two areas of memory to operate in: one with read/write permissions (for dynamic data), and one with read/execute permissions (for code). Early versions of the tool used a single read/write/execute block of memory, but this approach doesn't work for platforms that enforce "w^x" memory models.

When executed without any memory-related options, the first stage of `asminject.py` allocates both blocks of memory. It places the second stage and inner payload in the read/execute block, and uses the read/write block to store data. Once the payload finishes executing, `asminject.py` deallocates the read/write block, but not the read/execute block (because that's where the code is running from). This means that if you run it against the same process multiple times, it will accrue an additional read/write memory block each time. The blocks are very small (32k by default), but can add up if many injections are performed, and the increasing number of blocks may appear suspicious to administrators or security software.

If you add the `--do-not-deallocate` option when calling `asminject.py`, it will leave both blocks allocated in the target process when it exits, and indicate how to reuse them the next time you inject code into the same process, e.g.:

```
# python3 ./asminject.py 2684562 execute_python_code.s \
    --relative-offsets-from-binaries \
	--non-pic-binary "/usr/bin/python3\\.[0-9]+" \
	--var pythoncode "print('injected python code');" \
	--do-not-deallocate

...omitted for brevity...
[+] Done!
[+] To reuse the existing read/write and read execute memory allocated during 
    this injection attempt, include the following options in your next 
	asminject.py command: --use-read-execute-address 0x7ffff7faf000 
	--use-read-execute-size 0x8000 --use-read-write-address 0x7ffff7fb7000 
	--use-read-write-size 0x8000
```

i.e. to inject the same code into the same process again:

```
# python3 ./asminject.py 2684562 execute_python_code.s \
    --relative-offsets-from-binaries \
	--non-pic-binary "/usr/bin/python3\\.[0-9]+" \
	--var pythoncode "print('injected python code');" \
	--do-not-deallocate \
	--use-read-execute-address 0x7ffff7faf000 \
	--use-read-execute-size 0x8000 \
	--use-read-write-address 0x7ffff7fb7000 \
	--use-read-write-size 0x8000
```

## Anti-forensics

Security software or a very determined investigator could theoretically look for traces of `asminject.py` payloads in the read/write and read/execute memory blocks discussed above. To wipe those blocks after the payload has finished, include the ``--clear-payload-memory`` option. This will overwrite all of the payload's read/execute memory, and all of the payload's read/write memory *except* for the block used for script/payload communication.

By default, this feature will write null bytes (`0x00`), but any integer that can be represented using a number of bytes equal to the word length of the CPU can be used by including the ``--clear-payload-memory-value`` option. For example:

~~~
# python3 ./asminject.py 1494 printf_with_copy.s \
    --relative-offsets relative_offsets-libc-2.28.txt \
	--var message "ABCDEFGHIJKLMNOPQRSTUVWXYZ" --debug \
	--clear-payload-memory \
	--clear-payload-memory-value 0x00c651e0 \
	--use-read-execute-address 0xb6618000 \
	--use-read-execute-size 0x6e000 \
	--use-read-write-address 0xb6686000 \
	--use-read-write-size 0x29000 \
	--do-not-deallocate

...omitted for brevity...
[*] Waiting 2.0 second(s) before clearing payload read/write memory
[*] Overwriting payload read/write block starting at CPU state backup address (0xb6687000) in target process memory with 0x28000 bytes
[*] Notifying payload that cleanup is complete
[*] Setting script state to script_cleanup_complete (0xd64b04) at 0xb6686004 in target memory
[*] Waiting 2.0 second(s) before clearing payload read/execute memory
[*] Overwriting payload read/execute block (0xb6618000) in target process memory with 0x6e000 bytes
[*] Finished at 2022-06-29T21:18:54.783319 (UTC)
...omitted for brevity...

(gdb) x/8x 0xb6618000
0xb6618000:	0x00c651e0	0x00c651e0	0x00c651e0	0x00c651e0
0xb6618010:	0x00c651e0	0x00c651e0	0x00c651e0	0x00c651e0
(gdb) x/8x 0xb6686000
0xb6686000:	0x00c651e0	0x00180914	0x00c651e0	0x00c651e0
0xb6686010:	0x00c651e0	0x00c651e0	0x00c651e0	0x00c651e0
~~~

By default, `asminject.py` will perform the memory-clearing operation after a brief delay, to help avoid crashes where a thread was spawned that keeps referring to the object in payload memory. You can adjust the delay by specifying the `--clear-payload-memory-delay <SECONDS>` option.

## Restoring more of the target process's memory

Under normal operating conditions, `asminject.py` backs up and restores only the areas of the target process memory that it explicitly overwrites when placing the first stage and when communicating with the first and second stages of the payload. If your payload causes significant changes to the state of the process, it may be helpful to restore one or more entire regions of memory.

The `--restore-memory-region` option can be used to specify a regular expression for matching the path of a memory-mapped region, and may be specified multiple times. e.g.: `--restore-memory-region '[heap]' --restore-memory-region '[stack]'`.

The `--restore-all-memory-regions` option will cause `asminject.py` to attempt a backup and restore of *all* regions in the target process, with the exception of the kernel interface regions `[vdso]` and `[vvar]`.

## Payload obfuscation

Many of `asminject.py`'s parameters are always randomized to help prevent static fingerprint-based detection of its payloads. In addition, it supports optional payload obfuscation to help make fingerprinting approaches even less practical.

`--obfuscate` enables the payload obfuscation functionality, and causes random assembly code snippets that are effectively no-ops to be inserted at random locations in the payload source before it is passed to the assembler.

`--per-line-obfuscation-percentage` accepts an integer value of `1` to `100`, and controls the likelihood of whether or not obfuscation fragments will be inserted between each line (where such insertion is determined to be valid). If this value is not specified, `asminject.py` defaults to 50% probability.

`--obfuscation-iterations` accepts an integer value of `1` or more, and controls how many times `asminject.py` recursively applies the obfuscation process to payload source code. If this value is not specified, `asminject.py` defaults to only a single iteration. Values of `1` - `4` are suggested. Values greater than `5` are not recommended due to the amount of time the operation will take. A value of `5` will typically increase the size of the payload source file by about 500 - 2,000 times, and the compiled payload by about 250 - 1,500 times.

## Debugging/troubleshooting options

`--debug` will cause `asminject.py` to log a large amount of additional information, including the generated assembly source code for the first and second stage payloads.

`--temp-dir` specifies a custom base path for temporary files. When this option is not specified, `asminject.py` generates a unique path based on the current date/time and a secure random number.

`--preserve-temp-files` prevents `asminject.py` from deleting any of the temporary files it generates.

`--write-assembly-source-to-disk` will cause the generated source code for the payload assembly files to be written to disk instead of just passed to the assembler via standard input. Can be useful for troubleshooting.

### Debugging obfuscated payloads

Because obfuscation is applied in a truly random, non-deterministic manner, it can make reproducing issues difficult when debugging issues with the target process. `asminject.py` can therefore be configured to save the payload source from one execution and reuse it in another execution.

If the `--write-assembly-source-to-disk` and `--preserve-temp-files` options are specified, several variations of the source code for each payload are written to disk. For purposes of this section, the "post-obfuscation, pre-variable-replacement" variation should be used. E.g.:

```
# python3 ./asminject.py 21637 execute_python_code.s \
    --relative-offsets-from-binaries \
	--non-pic-binary "/usr/bin/python.*" \
	--var pythoncode "print('injected python code');" --debug \
	--preserve-temp-files --write-assembly-source-to-disk \
	--obfuscate --obfuscation-iterations 4

...omitted for brevity...
[*] Writing post-obfuscation, pre-variable-replacement assembly source to '/tmp/20220615185024245932478624/assembly/tmpnbg5ju1h-stage_2-post-obfuscation-pre-replacement.s'
...omitted for brevity...
```

To reuse the source code for debugging purposes, add the `--use-stage-1-source` and/or `--use-stage-2-source` options when calling `asminject.py` again, e.g.:

```
# python3 ./asminject.py 21637 execute_python_code.s \
    --relative-offsets-from-binaries \
	--non-pic-binary "/usr/bin/python.*" \
	--var pythoncode "print('injected python code');" \
	--debug \
	--use-stage-2-source '/tmp/20220615185024245932478624/assembly/tmpnbg5ju1h-stage_2-post-obfuscation-pre-replacement.s'
```


### Pause options

`asminject.py` can be directory to pause before proceeding at certain key points in the injection process. This can make it easier to attach `gdb` to troubleshoot custom payloads. While paused, the payload will be running in a loop with a `nanosleep`-based delay between iterations.

`--pause-before-resume` pauses execution after the first stage has been injected, but before the target process is resumed.

`--pause-before-launching-stage2` pauses execution after stage one has injected stage two, but before launched stage two.

`--pause-before-memory-restore` pauses execution after the payload has indicated it is ready for target process memory to be restored, but before that restoration takes place.

`--pause-after-memory-restore` pauses execution after target process memory has been restored, but before stage two restores CPU state and jumps back to the original instruction pointer.

