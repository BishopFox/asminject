#!/bin/bash
# Shortcut for creating relative offset lists for use with asminject.py
# You may need to install binutils (e.g. apt install binutils) if the readelf binary is not already present

readelf -a --wide "$1" | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d" " -f3,9