#!/usr/bin/ruby
require 'date'

$example_global_var_1 = "AKIASADF9370235SUAS0"
$example_global_var_2 = "This value should not be disclosed"

$i = 0

while $i < 1000000  do
    timestamp = DateTime.now.iso8601
    puts("#{timestamp} - Loop count #{$i}")
    $i += 1
    sleep(5)
end