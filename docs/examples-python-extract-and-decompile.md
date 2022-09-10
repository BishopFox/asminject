# asminject.py examples - Python - Extract Python code from a running process and decompile it

<a href="../README.md">[ Back to the main README.md ]</a> - <a href="examples-python.md">[ Back to Python examples ]</a>

* [Extract Python code from a running Python process](#extract-python-code-from-a-running-python-process)
* [Extract and Decompile Python code from a running PyInstaller-based process](#extract-and-decompile-python-code-from-a-running-pyinstaller-based-process)

## Extract Python code from a running Python process

Often, using a standard Python decompilation tool such as [Decompyle++](https://github.com/zrax/pycdc), [Uncompyle6](https://github.com/rocky/python-uncompyle6), or [Decompyle3](https://github.com/rocky/python-decompile3) against files on disk (e.g. `.pyc` files) will meet your needs. If so, you should probably go ahead and do that. But sometimes those tools can't parse the files you have access to, or the content no longer exists on disk and is only present in memory.

The `tools/python` directory of the `asminject.py` repository contains a Python script named `recursive_marshal.py` that will attempt to dump just about everything it can about a Python (including PyInstaller-generated binary) process. It is hardcoded to write output to a directory tree beginning with `/tmp/marshalled`, so edit the `recursive_marshal_base_dir` variable if you'd like it to go somewhere else. Please note that for legacy Python 2 processes, you can try using `recursive_marshal-27.py` instead, but it may require modifications to work with Python versions prior to 2.7.

Transform the script into a giant one-liner and then pass it to `asminject.py`, e.g.:

```
# export PYTHONSCRIPT="`cat tools/python/recursive_marshal.py | sed -z 's/\n/\\\\n/g' | sed 's.".\\\\".g'`"

# python3 ./asminject.py 237465 execute_python_code.s --relative-offsets-from-binaries --var pythoncode "${PYTHONSCRIPT}"
```

If the target process is a regular Python script running in a Python interpreter, the output should include the original source code for any loaded modules. For example, consider the following output when the script was injected into used against the `practice/python_loop-with_library.py` script:
```
Wrote entire source code for object __main__/example_python_library/important_thing to /tmp/marshalled/__main__/example_python_library/important_thing/___exported_object_source___.py
```

In this case, the exported data contains the entire original content of the `example_python_library/important_thing.py` script:

```
% cat /tmp/marshalled/__main__/example_python_library/important_thing/___exported_object_source___.py

important_thing_secret_value = "A very secret value that is only defined in example_python_library/important_thing.py"

class important_class_1:
    def __init__(self):
        self.important_hardcoded_value = "A very secret value that is only defined in the __init__ function for important_class_1 in example_python_library/important_thing.py"
    
    def ic1_print_ihv(self):
        print(self.important_hardcoded_value)
    
    @staticmethod
    def ic1_static_print_ihv():
        print("A very secret value that is only defined in the static_print_ihv function for important_class_1 in example_python_library/important_thing.py")

def it_print_itsv():
    print(important_thing_secret_value)

@staticmethod
def it_static_print_itsv():
    print("A very secret value that is only defined in example_python_library/important_thing.py's static method it_static_print_itsv")
```

The exported content will also include a lot of additional data, such as JSON definitions of object trees, source code for individual functions, and so on. This information is typically not necessary when the target process is a regular Python script running in a Python interpreter, but is important for other cases, and discussed further below.

## Extract and Decompile Python code from a running PyInstaller-based process

[PyInstaller](https://pyinstaller.org/) strips the source code property from objects, but there is still enough metadata left to reconstruct most of the same information from a process running in memory.

Begin the same way as when extracting content from a regular Python process. Transform the `recursive_marshal.py` script into a giant one-liner and then pass it to `asminject.py`, e.g.:

```
# export PYTHONSCRIPT="`cat tools/python/recursive_marshal.py | sed -z 's/\n/\\\\n/g' | sed 's.".\\\\".g'`"

# python3 ./asminject.py  237465 execute_python_code.s --relative-offsets-from-binaries --var pythoncode "${PYTHONSCRIPT}"
```

For PyInstaller binaries, the source code will most likely not be present, and so the output will look like this:

```
...omitted for brevity...
Couldn't get source code for __main__
Writing code to /tmp/marshalled/__main__/_pyi_main_co.bin
Couldn't get source code for __main__
Writing code to /tmp/marshalled/__main__/dump_code_object.bin
Couldn't get source code for __main__
Writing code to /tmp/marshalled/__main__/escape_json_value.bin
Couldn't get source code for __main__/example_python_library/important_thing/important_class_1
Writing code to /tmp/marshalled/__main__/example_python_library/important_thing/important_class_1/__init__.bin
Couldn't get source code for __main__/example_python_library/important_thing/important_class_1
Writing code to /tmp/marshalled/__main__/example_python_library/important_thing/important_class_1/ic1_print_ihv.bin
Couldn't get source code for __main__/example_python_library/important_thing/important_class_1
Writing code to /tmp/marshalled/__main__/example_python_library/important_thing/important_class_1/ic1_static_print_ihv.bin
Couldn't get source code for __main__/example_python_library/important_thing
Writing code to /tmp/marshalled/__main__/example_python_library/important_thing/it_print_itsv.bin
Couldn't get source code for __main__
Writing code to /tmp/marshalled/__main__/iteratively_dump_object.bin
...omitted for brevity...
```

In this case, you can use [Decompyle++](https://github.com/zrax/pycdc) on the binary files, looking in the corresponding JSON file to determine the Python major and minor version (3.10 in this case):

```
% jq . /tmp/marshalled/__main__/example_python_library/important_thing/important_class_1/ic1_static_print_ihv.json \
	| grep -P '(marshalled_file|python_version)'

  "marshalled_file": "/tmp/marshalled/__main__/example_python_library/important_thing/important_class_1/ic1_static_print_ihv.bin",
  "python_version": "sys.version_info(major=3, minor=10, micro=5, releaselevel='final', serial=0)"

% pycdc -c -v 3.10 /tmp/marshalled/__main__/example_python_library/important_thing/important_class_1/ic1_static_print_ihv.bin

...omitted for brevity...
print('A very secret value that is only defined in the static_print_ihv function for important_class_1 in example_python_library/important_thing.py')
```

The marshalled binary version of code from the main/initial script should be located in `__main__/_pyi_main_co.bin`, e.g.:

```
% pycdc -c -v 3.10 /tmp/marshalled-01-pyinstaller/__main__/_pyi_main_co.bin
 
...omitted for brevity...
import time
import datetime
import example_python_library
import example_python_library.important_thing as example_python_library
example_global_var_1 = 'AKIASADF9370235SUAS0'
example_global_var_2 = 'This value should not be disclosed'
for i in range(0, 1000000):
    print(datetime.datetime.utcnow().isoformat() + ' - Loop count ' + str(i))
    time.sleep(5)
```

Interesting properties may also be found in the JSON-formatted object tree exports, e.g.:

```
% jq . __main__/___exported_object_metadata___.json

{
...omitted for brevity...
"example_global_var_1": "AKIASADF9370235SUAS0",
"example_global_var_2": "This value should not be disclosed",
...omitted for brevity...
```

The combination of decompiled source code and the JSON files should allow a scripted reconstruction of something closer to the original code base, and this page will eventually be updated to describe that process.

It's also possible to perform a more targeted analysis without the lengthy custom script, e.g.:

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

To retrieve and decompile only the main script:

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


