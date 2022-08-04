## asminject.py - differences from dlinject.py

`dlinject.py` was written specifically to cause the target process to load a shared library from disk. It does this by injecting code into the target process that calls the `_dl_open` function in the `ld` shared library. This works on some versions of some Linux distributions, but [there is an open issue for the project because that symbol is not consistently exported by the library](https://github.com/DavidBuchanan314/dlinject/issues/8). `asminject.py` extends that basic concept significantly by injecting arbitrary code into the target process, and includes templates to perform a variety of actions (execute arbitrary Python, PHP, or Ruby code inside an existing process for one of those languages, copying files using syscalls, and so on). It also includes templates that emulate the original `dlinject.py` and load a shared library into the target process using several different methods, and this is discussed in more detail in <a href="docs/examples-shared_library_injection.md">the shared library injection examples document</a>.

`dlinject.py` writes the second stage code to disk, and the first stage payload reads that file into memory. `asminject.py` sets up a two-way communication channel entirely in process memory, so the target process does not load any potentially suspicious code from the filesystem.

`dlinject.py` includes assembly code specifically for the x86-64 architecture. `asminject.py` was designed for multiple architectures, and currently includes x86-64, 32-bit x86, and ARM32 payloads.

`dlinject.py` allocates one block of read/write/execute memory for the payload. `asminject.py` creates a read/write and a read/execute block so that the payload is more likely to operate normally on more restrictive platforms.

`dlinject.py` attempts to back up the target processes' stack before injection, and restore it after injection. `asminject.py` can optionally back up and restore memory regions, but defaults to using the stack normally, to hopefully avoid destabilizing multithreaded processes.

`asminject.py` introduces the following additional features:

* Templates and reusable code fragments for payloads
* Regular expression matching for executable/library and function names, to allow payloads to work in more cases without modification
* Multi-platform support (currently x86-64, x86, and ARM32)
* "Time-dilation" alternative to actually pausing the target process
* Can be used without modification against containerized processes
* Payloads are somewhat non-deterministic by default, and can be actively obfuscated to help evade detection
* Memory allocated by payloads can be reused between injections against the same process, to help evade detection
* Memory allocated by payloads can be actively wiped after the payload is complete, to remove forensic evidence
* Arbitrary blocks of memory in the target process can be backed up before injection, and restored afterward, to improve results in complex processes and also help remove forensic evidence
