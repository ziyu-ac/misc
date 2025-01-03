#!/bin/bash
for d in */; do echo -e "\n=== $d" && git -C "$d" status -s; done
