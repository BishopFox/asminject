<?php

for ($x = 0; $x <= 1000000; $x++)
{
  $current_timestamp = date(DATE_ISO8601);
  echo "$current_timestamp - Loop count $x\n";
  sleep(5);
}

?> 