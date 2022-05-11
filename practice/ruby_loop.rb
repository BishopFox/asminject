#!/usr/bin/ruby
require 'date'

$i = 0

while $i < 1000000  do
    timestamp = DateTime.now.iso8601
    puts("#{timestamp} - Loop count #{$i}")
    $i += 1
    sleep(5)
end