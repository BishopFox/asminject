# asminject.py
`asminject.py` is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes by accessing `/proc/<pid>/mem` instead of attaching via the debugger interface. Useful for tampering with trusted processes, certain post-exploitation scenarios, recovering content from process memory when the debugger interface is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

* [Origins](#origins)
* [Getting started](#getting-started)
* [Differences from dlinject.py](#differences-from-dlinjectpy)
* [Practice targets](#practice-targets)
* [Examples](#examples)
* <a href="docs/specialized_options.md">Specialized options</a>
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

Make sure you have `gcc`, `objcopy`, and `readelf` installed. `gcc` is generally part of the `gcc` package for most Linux distributions. `objcopy` and `readelf` are generally part of the `binutils` package for most Linux distributions.

In one terminal window, start a Python script that will not exit immediately. For example:

```
% python3 practice/python_loop.py 

2022-08-03T18:00:40.474030 - Loop count 0
2022-08-03T18:00:45.480180 - Loop count 1
2022-08-03T18:00:50.486070 - Loop count 2
```

In a second terminal window, `su` to `root`. Install the requirements for the package, then locate the Python loop process. For example:

```
# pip3 install requirements.txt

# ps auxww | grep python3

user        1565376  [...] python3 practice/python_loop.py
...omitted for brevity...
```

Examine the memory maps for the target process (in this case, PID 3022) to see if this version of Python was compiled with all functionality in the main executable, or to place it in a separate `libpython` file:

```
# cat /proc/1565376/maps | grep python

55ee0acfa000-55ee0ad66000 r--p [...] /usr/bin/python3.10
55ee0ad66000-55ee0b014000 r-xp [...] /usr/bin/python3.10
55ee0b014000-55ee0b254000 r--p [...] /usr/bin/python3.10
55ee0b255000-55ee0b25b000 r--p [...] /usr/bin/python3.10
55ee0b25b000-55ee0b29b000 rw-p [...] /usr/bin/python3.10
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
# python3 ./asminject.py 1565376 execute_python_code.s \
   --relative-offsets-from-binaries \
   --var pythoncode "print('injected python code')"

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.38
Ben Lincoln, Bishop Fox, 2022-08-03
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[*] Using autodetected processor architecture 'x86-64'
[*] Using '/tmp/202208031804573049878cbf670' as the base temporary directory
[*] Starting at 2022-08-03T18:04:57.311457 (UTC)
...omitted for brevity...
[*] Validation assembly of stage 2 succeeded
[*] Switching to super slow motion, like every late 1990s/early 2000s action film director did after seeing _The Matrix_...
...omitted for brevity...
[*] Wrote first stage shellcode at 0x7ffff7cfcfc4 in target process 1565435
[*] Returning to normal time
...omitted for brevity...
[*] Writing stage 2 to 0x7ffff749b000 in target memory
...omitted for brevity...
[*] Finished at 2022-08-03T18:05:01.125542 (UTC)
[*] Deleting the temporary directory '/tmp/202208031804573049878cbf670' and all of its contents
```

In the first terminal window, observe that the injected code has executed:

```
2022-08-03T18:04:53.024458 - Loop count 11
injected python code
2022-08-03T18:05:02.037101 - Loop count 12
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

## But what about Yama's ptrace_scope restrictions?

If you are an authorized administrator of a Linux system where someone has accidentally set `/proc/sys/kernel/yama/ptrace_scope` to 3, or are conducting an authorized penetration test of an environment where that value has been set, see the <a href="ptrace_scope_kernel_module/">ptrace_scope_kernel_module directory</a>.

## Future goals

* Implement inline code fragments to supplement the existing "import each fragment only once because they're all functions" model.
  * This is specifically to support a reusable pair of stack-alignment macros that can be used right before and after calls to library functions instead of the existing ad hoc inline code.
* Allow shellcode to be passed via stdin in addition to the current method of reading from a file.
* For Python and other script interpreters with APIs for passing in compiled bytecode for execution (versus `eval`-style execution of human-readable script code), provide payloads to take advantage of this ability for even more stealth.
* If feasible, inject Java code into Java processes via the JNI.
* Add alternative shared library injection methods for various scenarios.
* Add options to hook a specific method (or address, etc.) as an alternative to the current "hook the next syscall" technique that was inherited from `dlinject.py`.
* Provide a way to use the tool for quasi-debugging, e.g. hook a function and output the arguments passed to it every time it's called.
  * It might make more sense to find a way to inject Frida using `asminject.py` - more research is required.
* Develop interactive payloads, e.g. instead of injecting a particular line of Python script code into a Python process, `asminject.py` could prompt the operator for a line of code to inject, inject it, return the resulting output, and then prompt the operator for another line of code.
  * This might also make more sense to handle using Frida, if Frida can be injected into a process using `asminject.py` in a way that avoids Frida's need to invoke the debugger interface temporarily.
* Provide a way to interact with a target process running on a processor architecture that doesn't match the one where `asminject.py` is running. e.g. interact with a remote device using hardware like a PCI leech, exploit extreme corner cases like devices with `/proc/mem` accessible as root over an NFS share, etc.
* Add more elaborate obfuscation fragments.

