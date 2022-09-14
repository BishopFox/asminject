#!/usr/bin/env python

import time
import datetime
import example_python_library
import example_python_library.important_thing

example_global_var_1 = "AKIASADF9370235SUAS0"
example_global_var_2 = "This value should not be disclosed"
# next line can be used to ensure that the corresponding object is in memory
# but is not necessary for important_thing to show up
#ioit = example_python_library.important_thing.important_class_1()

for i in range(0, 1000000):
    print(datetime.datetime.utcnow().isoformat() + " - Loop count " + str(i))
    time.sleep(5)