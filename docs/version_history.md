## asminject.py - Version history

### 0.38 (2022-08-03)

* 32-bit x86 `dlinject-ld-threaded.s` and `dlinject-ld.s` payloads now use the real `__libc_argc`,  `__libc_argv`, and `_environ` symbols exported by `libc`, like the x86-64 versions introduced in version 0.37
* Fixed a stack-misalignment bug in `asminject_libpthread_pthread_create.s`, `asminject_libc_or_libdl_dlopen.s`, and `asminject_libc_printf.s` fragments.
* Fixed a stack-misalignment bug in `execute_php_code.s` that only affected Ubuntu.
* Fixed a typo in the updated `get_relative_offsets.sh` script
* Fixed a bug in recursively applying fragment references that seemed to only affect ARM32 payloads
* Documentation updates

### 0.37 (2022-08-02)

* Re-engineered relative offset model to tie symbol names to specific binary paths
  * This was necessary to fix some issues with the more flexible regular expressions that reference some functions
  * It doesn't change the operator experience, but does affect the assembly code for all architectures
    * Old-style library function reference: `mov r9, [BASEADDRESS:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:BASEADDRESS] + [RELATIVEOFFSET:^fopen($|@@.+):RELATIVEOFFSET]`
	* New-style library function reference: `mov r9, [SYMBOL_ADDRESS:^printf($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]`
	* If you've written custom payloads that reference functions in other binaries, you'll need to convert them to the newer syntax
	* Payloads for x86 and ARM32 that reference library functions are generally much shorter now
  * Additionally, use of other types of symbols is now supported and encouraged
    * For example, the new x86-64 versions of `dlinject-ld.s` and `dlinject-ld-threaded.s` reference the `__libc_argc`,  `__libc_argv`, and `_environ` symbols exported by `libc`	
* Assembly using `gcc` now uses the following workaround for all architectures:
  * Assemble the payload normally (i.e. the intermediate output is an ELF, not raw binary/shellcode)
  * Call `objcopy` to extract 
  * Previously, `x86-64` simply added the `-Wl,--oformat=binary` flag to `gcc`, and this caused `gcc` to emit a raw binary, with no need to call `objcopy` at all. This worked fine on Debian-derived distributions, but on OpenSUSE, the binary still contained a header, and this broke the injection step.
* Bug fixes to 32-bit x86 obfuscation code
* Fixed a bug in the ARM32 library injection fragment that made it unreliable
* Fixed incomplete ARM32 `dlinject-threaded.s` payload that was broken
* Added `dlinject-ld.s` and `dlinject-ld-threaded.s` payloads for x86-64
* Added basic processor architecture autodetection feature
* Documentation updates

### 0.36 (2022-08-01)

* Bug fixes for recent changes
* Better documentation
* Added a threaded version (`dlinject-ld-threaded.s`) of the experimental 32-bit x86 payload `dlinject-ld.s` introduced in version 0.35
* Standardized payload naming conventions

### 0.35 (2022-07-28)

* Finished porting the following payloads and related fragments to x86 architecture, bringing it to parity with x86-64 and ARM32:
  * `dlinject.s`
  * `dlinject-threaded.s`
  * `execute_precompiled.s`
  * `execute_precompiled-threaded.s`
* `dlinject.s` and `dlinject-threaded.s` for all three architectures will now find the `dlopen` function whether it's exported by `libdl` (as before) or `libc` (as it is on some other Linux distributions)
* Added a new, experimental `dlinject-ld.s` payload, currently only for 32-bit x86, that calls the `_dl_open` function in the `ld` library instead of `dlopen` in `libdl` or `libc`, as this may be useful in some cases
* `execute_python_code.s` should now work whether the Linux distribution places the necessary functions in a separate `libpython` or embeds them directly into the `python` binary, instead of requiring a separate `execute_python_code-libpython.s`
* All of the payloads for all architectures that depend on `libpthread` functions should now find them whether they're in a separate `libpthread` library or included in `libc`
  
### 0.34 (2022-07-27)

* Finished porting the following payloads and related fragments to x86 architecture:
  * `execute_python_code.s`
  * `execute_python_code-libpython.s`
  * `execute_php_code.s`
  * `execute_ruby_code.s`
  * `copy_file_using_libc.s`
  * `copy_file_using_syscalls.s`
* More flexible regexes for identifying the `php` binary

### 0.33 (2022-07-26)

* Added initial support for 32-bit x86 architecture (only the `printf.s` payload has been ported at this time)
* More flexible regexes for identifying `libc`, `libpthread`, and `libdl`

### 0.32 (2022-07-05)

* Fixed Ruby injection
* Fixed PHP injection
* Additional minor bug fixes

### 0.31 (2022-07-01)

* Updated `libdl` fragments to make them work across a wider variety of configurations for that library
* Updated `libc` fragments to make them work across a wider variety of configurations for that library
* Some PHP and Ruby injection is currently broken, maybe due to patches to recent versions of those binaries

### 0.30 (2022-07-01)

* Updated `libpthread` fragments to make them work across a wider variety of configurations for that library
* Added missing entries to `requirements.txt`

### 0.29 (2022-06-29)

* Updated the staging code for both x86-64 and ARM32 to take better advantage of reusable functions
* Added ``--clear-payload-memory``, ``--clear-payload-memory-value``, and ``--clear-payload-memory-delay`` anti-forensics options

### 0.28 (2022-06-15)

* Added a few more obfuscation fragments for ARM32 to bring it more or less to parity with x86-64
* Fixed an obfuscation-related bug in the ARM32 stage 2 template

### 0.27 (2022-06-15)

* Payload obfuscation now works correctly for ARM32 payloads (in addition to x86-64).
* The order of CPU state save/restore instructions in the stage 1 and 2 code is now randomized to make fingerprinting more difficult.
* Added `--use-stage-1-source` and `--use-stage-2-source` debugging options.
* Various bug fixes and improvements

### 0.26 (2022-06-14)

* Added payload obfuscation options: `--obfuscate`, `--per-line-obfuscation-percentage`, and `--obfuscation-iterations` (x86-64 only for this release).

### 0.25 (2022-06-10)

* Added `--relative-offsets-from-binaries` option to attempt to load symbol/offset data directly from files referenced in the target process memory map, if the target process is *not* running in a container
* Fixed some bugs in the ARM32 staging code introduced with the rework

### 0.24 (2022-06-09)

* Reworked the fragment approach so that code fragments are only imported once per payload, and the order is randomized to make payload detection harder
* The initial script/payload communication area in the stack is now only used briefly, with communication switching to an area in the r/w block allocated by the payload, to make detection harder and reduce the chances of destabilizing the target process
* The location of the initial script/payload communication area is now randomized, to make detection harder
* Fixed some bugs related to reusing memory between payloads

### 0.22 (2022-06-03)

* Fixed some bugs that crept into the ARM32 code during the rework

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
