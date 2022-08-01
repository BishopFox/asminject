# asminject.py
`asminject.py` is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes by accessing `/proc/<pid>/mem` instead of attaching via the debugger interface. Useful for tampering with trusted processes, certain post-exploitation scenarios, recovering content from process memory when the debugger interface is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

* [Origins](#origins)
* [Getting started](#getting-started)
* [Differences from dlinject.py](#differences-from-dlinjectpy)
* [Practice targets](#practice-targets)
* [Examples](#examples)
* <a href="docs/specialized_options.md">Specialized options</a>
* [Relative offsets](#relative-offsets)
* [But what about Yama's ptrace_scope restrictions?](#but-what-about-yamas-ptrace_scope-restrictions)
* [Future goals](#future-goals)
* <a href="docs/version_history.md">Version history</a>

## Origins

`asminject.py` was written for two primary scenarios in penetration testing within Linux environments:

* Attacking process- and container-level security controls from the perspective of an attacker with root access to the host
* Avoiding detection after successfully exploiting another issue

For example, consider a penetration test in which the tester has obtained root access to a server that hosts many containers. One of the containers processes bank transfers, and has a very robust endpoint security product installed within it. When the pen tester tries to modify the bank transfer data from within the container, the endpoint security software detects and blocks the attempt. `asminject.py` allows the pen tester to inject arbitrary code directly into the banking software's process memory or even the endpoint security product from outside of the container. Like a victim of Descartes' "evil demon", the security software within the container is helpless, because it exists in an environment entirely under the control of the attacker.

The original `dlinject.py` was designed specifically to load Linux shared libraries into an existing process. `asminject.py` does everything the original did and much more. It executes arbitrary assembly code, and includes templates for a variety of attacks. It has also been redesigned to help avoid detection by security mechanisms that key off of potentially suspicious activity like library-loading events.

## Getting started

Make sure you have `gcc` installed.

In one terminal window, start a Python script that will not exit immediately. For example:

```
% python3 practice/python_loop.py 

2022-07-01T18:00:59.138716 - Loop count 0
2022-07-01T18:01:04.144467 - Loop count 1
```

In a second terminal window, `su` to `root`. Install the requirements for the package, then locate the `bash` loop process. For example:

```
# pip3 install requirements.txt

# ps auxww | grep python3

user        3022  0.2  0.2  17632  9132 pts/0    S+   11:00   0:00 python3 practice/python_loop.py
...omitted for brevity...
```

Examine the memory maps for the target process (in this case, PID 3022) to see if this version of Python was compiled with all functionality in the main executable, or to place it in a separate `libpython` file:

```
# cat /proc/3022/maps | grep python

55ee0acfa000-55ee0ad66000 r--p 00000000 08:01 3018726                    /usr/bin/python3.10
55ee0ad66000-55ee0b014000 r-xp 0006c000 08:01 3018726                    /usr/bin/python3.10
55ee0b014000-55ee0b254000 r--p 0031a000 08:01 3018726                    /usr/bin/python3.10
55ee0b255000-55ee0b25b000 r--p 0055a000 08:01 3018726                    /usr/bin/python3.10
55ee0b25b000-55ee0b29b000 rw-p 00560000 08:01 3018726                    /usr/bin/python3.10
```

If there is no separate `libpython` listed, determine if the main executable is using position-independent code or not. For example, on my test system, the `python3.9` binary is *not* position-independent, but the `python2.7` and `python3.10` binaries *are*:

```
# file /usr/bin/python2.7

/usr/bin/python2.7: ELF 64-bit LSB pie executable [...]
                               ^^^^^^^^^^^^^^^^^^

# file /usr/bin/python3.9

/usr/bin/python3.9: ELF 64-bit LSB executable [...]
                               ^^^^^^^^^^^^^^

# file /usr/bin/python3.10

/usr/bin/python3.10: ELF 64-bit LSB pie executable [...]
                                ^^^^^^^^^^^^^^^^^^
```

Determining this can be slightly tricky, and is discussed further in the <a href="docs/specialized_options.md#specifying-non-pic-code">specialized options document</a>. In this case, the target process' main executable is position-independent, because it is running in Python 3.10, but if I were targeting a Python 3.7 or 3.9 process, I'd add the option `--non-pic-binary "/usr/bin/python3\\.[0-9]+"` to the example command below.

Call `asminject.py`, specifying the name of the payload (`execute_python_code.s`), and the `pythoncode` variable name and value. In this case, the Python code `print('injected python code');` is specified to give an obvious indication of successful injection.

```
# python3 ./asminject.py 3249 execute_python_code.s \
  --arch x86-64 --relative-offsets-from-binaries --stop-method "slow" \
  --var pythoncode "print('injected python code');"

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.29
Ben Lincoln, Bishop Fox, 2022-06-29
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[*] Using '/tmp/2022070118105745678686b6a36' as the base temporary directory
[*] Starting at 2022-07-01T18:10:57.461600 (UTC)
...omitted for brevity...
[*] Switching to super slow motion, like every late 1990s/early 2000s action film director did after seeing _The Matrix_...
...omitted for brevity...
[*] Using: 0x91cd86 for 'ready for stage two write' state value
[*] Using: 0x142b62 for 'stage two written' state value
[*] Using: 0x90d76 for 'ready for memory restore' state value
[*] Wrote first stage shellcode at 0x7f1ea8d24fc4 in target process 3249
[*] Returning to normal time
...omitted for brevity...
[*] Waiting for stage 1 to indicate that it is ready to switch to a new communication address
...omitted for brevity...
[*] Waiting for stage 1 to indicate that it has allocated additional memory and is ready for the script to write stage 2
...omitted for brevity...
[*] Writing stage 2 to 0x7f1ea8564000 in target memory
...omitted for brevity...
[+] Payload has been instructed to launch stage 2
[*] Waiting for stage 2 to indicate that it is ready for process memory to be restored
...omitted for brevity...
[*] Restoring original memory content
[*] Waiting for payload to indicate that it is ready for cleanup
[*] Waiting for payload to update the state value to payload_ready_for_script_cleanup (0x7cf398) at address 0x7f1ea8590000
[*] Notifying payload that cleanup is complete
...omitted for brevity...
[*] Finished at 2022-07-01T18:11:02.213313 (UTC)
[*] Deleting the temporary directory '/tmp/2022070118105745678686b6a36' and all of its contents
```

In the first terminal window, observe that the injected code has executed:

```
2022-07-01T18:10:53.359356 - Loop count 4
injected python code
2022-07-01T18:11:02.374622 - Loop count 5
```

## Differences from dlinject.py

`dlinject.py` was written specifically to cause the target process to load a shared library from disk. It does this by injecting code into the target process that calls the `_dl_open` function in the `ld` shared library. This works on some versions of some Linux distributions, but [there is an open issue for the project because that symbol is not consistently exported by the library](https://github.com/DavidBuchanan314/dlinject/issues/8). `asminject.py` extends that basic concept significantly by injecting arbitrary code into the target process, and includes templates to perform a variety of actions (execute arbitrary Python, PHP, or Ruby code inside an existing process for one of those languages, copying files using syscalls, and so on). It also includes templates that emulate the original `dlinject.py` and load a shared library into the target process using several different methods, and this is discussed in more detail in <a href="docs/examples-shared_library_injection.md">the shared library injection examples document</a>.

`dlinject.py` writes the second stage code to disk, and the first stage payload reads that file into memory. `asminject.py` sets up a two-way communication channel entirely in process memory, so the target process does not load any potentially suspicious code from the filesystem.

`dlinject.py` includes assembly code specifically for the x86-64 architecture. `asminject.py` was designed for multiple architectures, and currently includes both x86-64 and ARM32 payloads.

`dlinject.py` allocates one block of read/write/execute memory for the payload. `asminject.py` creates a read/write and a read/execute block so that the payload is more likely to operate normally on more restrictive platforms.

`dlinject.py` attempts to back up the target processes' stack before injection, and restore it after injection. `asminject.py` can optionally back up and restore memory regions, but defaults to using the stack normally, to hopefully avoid destabilizing multithreaded processes.

`asminject.py` introduces the following additional features:

* Templates and reusable code fragments for payloads
* Regular expression matching for executable/library and function names, to allow payloads to work in more cases without modification
* Multi-platform support (currently x86-64 and ARM32)
* "Time-dilation" alternative to actually pausing the target process
* Can be used without modification against containerized processes
* Payloads are somewhat non-deterministic by default, and can be actively obfuscated to help evade detection
* Memory allocated by payloads can be reused between injections against the same process, to help evade detection
* Memory allocated by payloads can be actively wiped after the payload is complete, to remove forensic evidence
* Arbitrary blocks of memory in the target process can be backed up before injection, and restored afterward, to improve results in complex processes and also help remove forensic evidence


## Practice targets

The `practice` directory of this repository includes basic looping code that outputs a timestamp and loop iteration to the console, so you can practice injecting various types of code in a controlled environment. These practice loops are referred to in the remaining examples.

## Examples

The basic syntax for calling `asminject.py` is:

```
# python3 ./asminject.py <target_process_id> <payload> \
  --arch [x86-64|x86|arm32] --relative-offsets-from-binaries --stop-method "slow" \
  --var <payload_variable_1_name> <payload_variable_1_value> \
  # ... \
  --var <payload_variable_n_name> <payload_variable_n_value>
```

In most cases, any of the payloads used in the examples will run on any of the supported architectures.

* <a href="docs/examples-basic.md">Basic examples</a> - simple payloads that e.g. cause an existing process to copy files for you
* <a href="docs/examples-python.md">Python code injection</a>
* <a href="docs/examples-php.md">PHP code injection</a>
* <a href="docs/examples-ruby.md">Ruby code injection</a>
* <a href="docs/examples-shellcode_injection.md">Shellcode/stager injection</a>
* <a href="docs/examples-shared_library_injection.md">Shared library injection</a>

## Relative offsets

Very basic `asminject.py` payloads can be written in pure assembly without referring to libraries. Some of the included payloads are of that design. Most interesting payloads require references to libraries that are loaded by the target process, so that functions in them can be called. The payloads included with `asminject.py` include comments describing which binaries they need relative offsets for. The references are handled as regular expressions, to hopefully make them more portable across versions.

Starting with version 0.25, `asminject.py` can attempt to load this symbol/offset data automatically from the binaries that are referenced in the memory map, by including the `--relative-offsets-from-binaries` option in the command line. This will *only* work if the target process is not running in a container, or if the container has the exact same library versions as the host OS. Note that this functionality requires the `elftools` Python library, which is not included with a standard Python installation. You'll need to install it via `pip3 install -r requirements.txt` or similar.

If your target process is running in a container, or you need to specify an explicit list of offsets for another reason, use the process below:

Examine the list of binaries and libraries that your target process is using, e.g.:

```
# ps auxww | grep python2

user     2144330  0.2  0.1  13908  7864 pts/2    S+   15:30   0:00 python2 ./calling_script.py
                                                                                                                                    
# cat /proc/2144330/maps

560a14849000-560a14896000 r--p [...] /usr/bin/python2.7
...omitted for brevity...
7fc63884b000-7fc638870000 r--p [...] /usr/lib/x86_64-linux-gnu/libc-2.31.so
...omitted for brevity...
7fc638a10000-7fc638a1f000 r--p [...] /usr/lib/x86_64-linux-gnu/libm-2.31.so
...omitted for brevity...
7fc638b54000-7fc638b57000 r--p [...] /usr/lib/x86_64-linux-gnu/libz.so.1.2.11
...omitted for brevity...
7fc638b71000-7fc638b72000 r--p [...] /usr/lib/x86_64-linux-gnu/libutil-2.31.so
...omitted for brevity...
7fc638b76000-7fc638b77000 r--p [...] /usr/lib/x86_64-linux-gnu/libdl-2.31.so
...omitted for brevity...
7fc638b7c000-7fc638b83000 r--p [...] /usr/lib/x86_64-linux-gnu/libpthread-2.31.so
...omitted for brevity...
7fc638bc3000-7fc638bc4000 r--p [...] /usr/lib/x86_64-linux-gnu/ld-2.31.so                                                                                                               
```

In this case, you could call exported functions in eight different binaries. Most of the example payloads will only use one or two, and will match their names based on regexes, but you'll still need to generate a list of the offsets for `asminject.py` to use. E.g. for this specific copy of `/usr/bin/python2.7`:

```
./get_relative_offsets.sh /usr/bin/python2.7 > relative_offsets-python2.7.txt
```

If you are injecting code into a containerized process from outside the container, you'll need to use the copy of each binary *from inside the container*, or you'll get the wrong data. This is why `asminject.py` doesn't just grab the offsets itself by default, like `dlinject.py` does.

## But what about Yama's ptrace_scope restrictions?

If you are an authorized administrator of a Linux system where someone has accidentally set `/proc/sys/kernel/yama/ptrace_scope` to 3, or are conducting an authorized penetration test of an environment where that value has been set, see the <a href="ptrace_scope_kernel_module/">ptrace_scope_kernel_module directory</a>.

## Future goals

* Allow shellcode to be passed via stdin in addition to the current method of reading from a file.
* For Python and other script interpreters with APIs for passing in compiled bytecode for execution (versus `eval`-style execution of human-readable script code), provide payloads to take advantage of this ability for even more stealth.
* If feasible, inject Java code into Java processes via the JNI.
* Add alternative DLL injection methods for various scenarios.
* Add options to hook a specific method (or address, etc.) as an alternative to the current "hook the next syscall" technique that was inherited from `dlinject.py`.
* Provide a way to use the tool for quasi-debugging, e.g. hook a function and output the arguments passed to it every time it's called.
  * It might make more sense to find a way to inject Frida using `asminject.py` - more research is required.
* Develop interactive payloads, e.g. instead of injecting a particular line of Python script code into a Python process, `asminject.py` could prompt the operator for a line of code to inject, inject it, return the resulting output, and then prompt the operator for another line of code.
  * This might also make more sense to handle using Frida, if Frida can be injected into a process using `asminject.py` in a way that avoids Frida's need to invoke the debugger interface temporarily.
* Add more elaborate obfuscation fragments.

