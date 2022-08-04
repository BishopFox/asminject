## asminject.py - Getting started

Make sure you have `gcc`, `objcopy`, and `readelf` installed. `gcc` is generally part of the `gcc` package for most Linux distributions. `objcopy` and `readelf` are generally part of the `binutils` package for most Linux distributions.

In one terminal window, start a Python script that will not exit immediately. For example:

```
% python3 practice/python_loop.py 

2022-08-03T18:00:40.474030 - Loop count 0
2022-08-03T18:00:45.480180 - Loop count 1
2022-08-03T18:00:50.486070 - Loop count 2
```

In a second terminal window, `su` to `root`. Install the requirements for the package, then locate the Python loop process. For example:

```
# pip3 install requirements.txt

# ps auxww | grep python3

user        1565376  [...] python3 practice/python_loop.py
...omitted for brevity...
```

Examine the memory maps for the target process (in this case, PID 3022) to see if this version of Python was compiled with all functionality in the main executable, or to place it in a separate `libpython` file:

```
# cat /proc/1565376/maps | grep python

55ee0acfa000-55ee0ad66000 r--p [...] /usr/bin/python3.10
55ee0ad66000-55ee0b014000 r-xp [...] /usr/bin/python3.10
55ee0b014000-55ee0b254000 r--p [...] /usr/bin/python3.10
55ee0b255000-55ee0b25b000 r--p [...] /usr/bin/python3.10
55ee0b25b000-55ee0b29b000 rw-p [...] /usr/bin/python3.10
```

If there is no separate `libpython` listed, determine if the main executable is using position-independent code or not. For example, on my test system, the `python3.9` binary is *not* position-independent, but the `python2.7` and `python3.10` binaries *are*:

```
# file /usr/bin/python2.7

/usr/bin/python2.7: ELF 64-bit LSB pie executable [...]
                               ^^^^^^^^^^^^^^^^^^

# file /usr/bin/python3.9

/usr/bin/python3.9: ELF 64-bit LSB executable [...]
                               ^^^^^^^^^^^^^^

# file /usr/bin/python3.10

/usr/bin/python3.10: ELF 64-bit LSB pie executable [...]
                                ^^^^^^^^^^^^^^^^^^
```

Determining this can be slightly tricky, and is discussed further in the <a href="docs/specialized_options.md#specifying-non-pic-code">specialized options document</a>. In this case, the target process' main executable is position-independent, because it is running in Python 3.10, but if I were targeting a Python 3.7 or 3.9 process, I'd add the option `--non-pic-binary "/usr/bin/python3\\.[0-9]+"` to the example command below.

Call `asminject.py`, specifying the name of the payload (`execute_python_code.s`), and the `pythoncode` variable name and value. In this case, the Python code `print('injected python code');` is specified to give an obvious indication of successful injection.

```
# python3 ./asminject.py 1565376 execute_python_code.s \
   --relative-offsets-from-binaries \
   --var pythoncode "print('injected python code')"

                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.38
Ben Lincoln, Bishop Fox, 2022-08-03
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject

[*] Using autodetected processor architecture 'x86-64'
[*] Using '/tmp/202208031804573049878cbf670' as the base temporary directory
[*] Starting at 2022-08-03T18:04:57.311457 (UTC)
...omitted for brevity...
[*] Validation assembly of stage 2 succeeded
[*] Switching to super slow motion, like every late 1990s/early 2000s action film director did after seeing _The Matrix_...
...omitted for brevity...
[*] Wrote first stage shellcode at 0x7ffff7cfcfc4 in target process 1565435
[*] Returning to normal time
...omitted for brevity...
[*] Writing stage 2 to 0x7ffff749b000 in target memory
...omitted for brevity...
[*] Finished at 2022-08-03T18:05:01.125542 (UTC)
[*] Deleting the temporary directory '/tmp/202208031804573049878cbf670' and all of its contents
```

In the first terminal window, observe that the injected code has executed:

```
2022-08-03T18:04:53.024458 - Loop count 11
injected python code
2022-08-03T18:05:02.037101 - Loop count 12
```