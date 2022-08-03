# asminject.py examples - Basic examples
* [Create a world-readable copy of a file using only Linux syscalls](#create-a-world-readable-copy-of-a-file-using-only-linux-syscalls)
* [Create a copy of a file using buffered read/write libc calls](#create-a-copy-of-a-file-using-buffered-readwrite-libc-calls)
* [Print text to standard output](#print-text-to-standard-output)

## Create a world-readable copy of a file using only Linux syscalls

The `copy_file_using_syscalls.s` payload requires no relative offset information, because it's all done using Linux syscalls. It may also help avoid some methods of forensic detection versus using the `cp`, `cat`, or other shell commands.

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
   --relative-offsets-from-binaries \
   --var sourcefile "/etc/passwd" \
   --var destfile "/tmp/bishopfox.txt"

...omitted for brevity...

# cat /tmp/bishopfox.txt

root:x:0:0:root:/root:/usr/bin/zsh
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
...omitted for brevity...
```

## Create a copy of a file using buffered read/write libc calls

The `copy_file_using_libc.s` payload uses code that (like the previous example) creates a copy of a file, but by using libc's `fopen()`, `fread()`, `fwrite()`, and `fclose()` instead of syscalls, can easily use a buffered approach that's more efficient.

This payload requires relative offsets for the `libc` shared library used by the target process.

```
# python3 ./asminject.py 1876570 copy_file_using_libc.s \
   --relative-offsets-from-binaries \
   --var sourcefile "/etc/passwd" \
   --var destfile "/tmp/bishopfox.txt"
```

## Print text to standard output

The `printf.s` payload can be useful for debugging injecting into a particular target. It passes a format string and one parameter to the `libc` `printf` function.

This payload requires relative offsets for the `libc` shared library used by the target process.

```
python3 ./asminject.py 2258 printf.s \
   --relative-offsets-from-binaries \
   --var formatstring "DEBUG: '%s'" \
   --var message "12345"
```