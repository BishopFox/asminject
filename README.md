# asminject.py
`asminject.py` is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes without the use of ptrace by accessing `/proc/<pid>/mem`. Useful for certain post-exploitation scenarios, recovering content from process memory when ptrace is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

This utility should be considered an alpha pre-release. Use at your own risk.

* [Origins](#origins)
* [Generating lists of relative offsets](#generating-lists-of-relative-offsets)
* [Practice Targets](#practice-targets)
* [Examples](#examples)
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

## Practice targets

The `practice` directory of this repository includes basic looping code that outputs a timestamp and loop iteration to the console, so you can practice injecting various types of code in a controlled environment. These practice loops are referred to in the remaining examples.

## Examples

This section was getting too lengthy for the main `README.md`, so it's been moved into the following files:

* <a href="docs/examples-x86-64.md">Example usage for x86-64</a>
* <a href="docs/examples-arm32.md">Example usage for ARM32</a>

## Specialized Options

This section was getting too lengthy for the main `README.md`, so it's been moved into a separate <a href="docs/specialized_options.md">specialized options document</a>

## But what about Yama's ptrace_scope restrictions?

If you are an authorized administrator of a Linux system where someone has accidentally set `/proc/sys/kernel/yama/ptrace_scope` to 3, or are conducting an authorized penetration test of an environment where that value has been set, see the <a href="ptrace_scope_kernel_module/">ptrace_scope_kernel_module directory</a>.

## Version history

### 0.22 (2022-06-03)

* Fixed the refactoring bug that had broken Python code execution
* Added `--write-assembly-source-to-disk` debugging option
* More internal reworking

### 0.21 (2022-06-02)

* Read/write and read/execute memory region sizes are now randomly selected by default to help make detection harder
* Refactoring some of the inner workings to allow for ongoing improvements
* Python code execution payload segfaults after execution at the moment

### 0.20 (2022-06-01)

* Added `--restore-memory-region` and `--restore-all-memory-regions` options to allow more of the target process state to be restored after injection.

### 0.19 (2022-05-26)

* Work in progress version with some internal logic redesigned to support new features in a later release

### 0.18 (2022-05-20)

* Added support for reusing the same blocks of memory between runs of the tool, to make detection harder and avoid leaking (small) amounts of memory when injecting into the same process repeatedly
* Updated all of the existing x86-64 code to use the improved design developed while writing the ARM32 code
* Fixed ANSI terminal colours

### 0.17 (2022-05-18)

* ARM32 `copy_file_using_libc.s`, `execute_precompiled.s`, `execute_precompiled_threaded.s`, `dlinject.s`, and `dlinject_threaded.s` implemented, bringing ARM32 support to parity with x86-64
* Implemented regular expression matching for function/label names in relative offset references, to make `glibc's` version-numbers-in-function-names style easier to support
* Split documentation into separate files and expanded the ARM32 content

### 0.16 (2022-05-17)

* Implemented support for code fragment references in payloads to make more complex ARM32 payloads less unwieldy to write
* Work in progress on remaining ARM32 payloads

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
