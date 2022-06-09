# asminject.py examples - Python
* [Write all global or variables to standard out](#write-all-global-or-local-variables-to-standard-out)

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
# python3 ./asminject.py 249594 execute_python_code.s --arch x86-64 --relative-offsets relative_offsets-usr-bin-python3.9.txt --non-pic-binary "/usr/bin/python3\\.[0-9]+" --stop-method "slow" --var pythoncode "tmp = globals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items() if not k.startswith('_') and k!='tmp' and k!='In' and k!='Out' and not hasattr(v, '__call__')]"
```

or

```
# python3 ./asminject.py 249594 execute_python_code.s --arch x86-64 --relative-offsets relative_offsets-usr-bin-python3.9.txt --non-pic-binary "/usr/bin/python3\\.[0-9]+" --stop-method "slow" --var pythoncode "tmp = locals().copy(); [print(k,'  :  ',v,' type:' , type(v)) for k,v in tmp.items() if not k.startswith('_') and k!='tmp' and k!='In' and k!='Out' and not hasattr(v, '__call__')]"
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
