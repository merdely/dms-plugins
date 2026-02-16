#!/usr/bin/env python3

import subprocess
import json

cmd = [ 'env', 'FLATPAK_FANCY_OUTPUT=0', 'flatpak', 'list', '--columns=application,version' ]
output = subprocess.run(cmd, capture_output=True, text=True)

applist = {}

for line in output.stdout.splitlines():
    arr = line.split('\t')
    if len(arr) == 2:
        applist[arr[0]] = arr[1]

output = ""
cmd = [ 'env', 'FLATPAK_FANCY_OUTPUT=0', 'flatpak', 'remote-ls', '--updates', '--columns', 'name,application,version' ]
result = subprocess.run(cmd, capture_output=True, text=True)
if result.stdout:
    for line in result.stdout.splitlines():
        arr = line.split('\t')
        if len(arr) == 3:
            cur = applist[arr[1]]
            print(f"{{ \"name\": \"{arr[0]}\", \"id\": \"{arr[1]}\", \"currentVersion\": \"{cur}\", \"newVersion\": \"{arr[2]}\" }}")
