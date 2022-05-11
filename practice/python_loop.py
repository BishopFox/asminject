#!/usr/bin/env python

import time
import datetime

for i in range(0, 1000000):
    print(datetime.datetime.utcnow().isoformat() + " - Loop count " + str(i))
    time.sleep(5)