<?php

$example_global_var_1 = "AKIASADF9370235SUAS0";
$example_global_var_2 = "This value should not be disclosed";

for ($x = 0; $x <= 1000000; $x++)
{
  $current_timestamp = date(DATE_ISO8601);
  echo "$current_timestamp - Loop count $x\n";
  sleep(5);
}

?> 