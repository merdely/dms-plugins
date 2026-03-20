#!/usr/bin/env python3

import json
import subprocess
import sys
from urllib.error import URLError, HTTPError
from urllib.request import urlopen

cmd = [ 'env', 'FLATPAK_FANCY_OUTPUT=0', 'flatpak', 'list', '--columns=name,application,version' ]
output = subprocess.run(cmd, capture_output=True, text=True)

appname = {}
appvers = {}

for line in output.stdout.splitlines():
    arr = line.split('\t')
    if len(arr) == 3:
        appname[arr[1]] = arr[0]
        appvers[arr[1]] = arr[2]

def get_latest(app_id: str) -> str:
    try:
        with urlopen(f"https://flathub.org/api/v2/appstream/{app_id}", timeout=10) as response:
            content = response.read()
            json_string = json.loads(content.decode("utf-8"))
        return json_string['releases'][0]['version']
    except HTTPError as e:
        print(f"HTTP error: {e.code} {e.reason}", file=sys.stderr)
    except URLError as e:
        print(f"URL error: {e.reason}", file=sys.stderr)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
    return ""

for app in appname:
    new_ver=get_latest(app)
    if not new_ver or new_ver == appvers[app]:
        continue
    print(f"{{ \"name\": \"{appname[app]}\", \"id\": \"{app}\", \"currentVersion\": \"{appvers[app]}\", \"newVersion\": \"{new_ver}\" }}")

