# asminject.py
`asminject.py` is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into x86-64, x86, and ARM32 Linux processes by accessing `/proc/<pid>/mem` instead of attaching via the debugger interface. Useful for tampering with trusted processes, certain post-exploitation scenarios, recovering content from process memory when the debugger interface is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

In this document:

* [Origins](#origins)
* [Examples](#examples)
* [But what about Yama's ptrace_scope restrictions?](#but-what-about-yamas-ptrace_scope-restrictions)
* [Future goals](#future-goals)

Separate, more detailed documentation:

* <a href="docs/getting_started.md">Getting started</a>
* <a href="docs/differences_from_dlinject.md">Differences from dlinject.py</a>
* <a href="docs/specialized_options.md">Specialized options</a>
* <a href="docs/version_history.md">Version history</a>

## Origins

`asminject.py` was written for two primary scenarios in penetration testing within Linux environments:

* Attacking process- and container-level security controls from the perspective of an attacker with root access to the host
* Avoiding detection after successfully exploiting another issue

For example, consider a penetration test in which the tester has obtained root access to a server that hosts many containers. One of the containers processes bank transfers, and has a very robust endpoint security product installed within it. When the pen tester tries to modify the bank transfer data from within the container, the endpoint security software detects and blocks the attempt. `asminject.py` allows the pen tester to inject arbitrary code directly into the banking software's process memory or even the endpoint security product from outside of the container. Like a victim of Descartes' "evil demon", the security software within the container is helpless, because it exists in an environment entirely under the control of the attacker.

The original `dlinject.py` was designed specifically to load Linux shared libraries into an existing process. `asminject.py` does everything the original did and much more. It executes arbitrary assembly code, and includes templates for a variety of attacks. It has also been redesigned to help avoid detection by security mechanisms that key off of potentially suspicious activity like library-loading events.

## Examples

The `practice` directory of this repository includes basic looping code that outputs a timestamp and loop iteration to the console, so you can practice injecting various types of code in a controlled environment. These practice loops are referred to in the remaining examples.

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

Most Linux distributions include a kernel security module named Yama that controls access to use the `ptrace` capability against other processes. While `asminject.py` doesn't attach to the debugger interface, it still requires permission to use the `ptrace` capability. If you are receiving errors about this capability, check the content of `/proc/sys/kernel/yama/ptrace_scope`. If it's set to 2, then run the following command as `root`:

```
echo 1 > /proc/sys/kernel/yama/ptrace_scope
```

Values of 3 or higher cannot be unset without a reboot. However, if you are an authorized administrator of a Linux system where someone has accidentally set `/proc/sys/kernel/yama/ptrace_scope` to 3, or are conducting an authorized penetration test of an environment where that value has been set, see the <a href="ptrace_scope_kernel_module/">ptrace_scope_kernel_module directory</a> for a potential workaround that does not require a reboot.

## Future goals

* Add support for ARM64 (Aarch64).
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

