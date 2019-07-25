#!/bin/bash

find * -type f -exec sed 's/[ \t]*$//' -i {} \;

