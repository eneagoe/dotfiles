#!/usr/bin/env bash

for i in `gem list | cut -d" " -f1`; do echo "$i :" ; gem spec $i license; done
