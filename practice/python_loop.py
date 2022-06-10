#!/usr/bin/env python

import time
import datetime

example_global_var_1 = "AKIASADF9370235SUAS0"
example_global_var_2 = "This value should not be disclosed"

for i in range(0, 1000000):
    print(datetime.datetime.utcnow().isoformat() + " - Loop count " + str(i))
    time.sleep(5)