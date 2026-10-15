#!/usr/bin/env python3
"""Set one wallpaper on every display and Space macOS has stored, connected or not.

`set picture of every desktop` only reaches connected displays, so a monitor
plugged in later (or the laptop screen after clamshell use) shows its old
wallpaper. macOS keeps a wallpaper per display and per Space in WallpaperAgent's
store; this rewrites every stored image wallpaper there and restarts the agent so
it loads the file and repaints the connected displays.

The store format is undocumented. If it holds no image wallpaper this exits 1, so
the caller can fall back to osascript.

Usage: set_wallpaper_everywhere.py <image>
"""
import os
import pathlib
import plistlib
import subprocess
import sys
import tempfile

STORE = os.path.expanduser("~/Library/Application Support/com.apple.wallpaper/Store/Index.plist")
IMAGE = "com.apple.wallpaper.choice.image"

url = pathlib.Path(sys.argv[1]).resolve().as_uri()

with open(STORE, "rb") as f:
    store = plistlib.load(f)

found = changed = 0


def walk(node):
    global found, changed
    if isinstance(node, dict):
        if node.get("Provider") == IMAGE and "Configuration" in node:
            found += 1
            config = plistlib.loads(node["Configuration"])
            if config.get("url", {}).get("relative") != url:
                config["url"] = {"relative": url}
                node["Configuration"] = plistlib.dumps(config, fmt=plistlib.FMT_BINARY)
                changed += 1
        for value in node.values():
            walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)


walk(store)

if not found:
    sys.exit("no image wallpaper in the store; format changed?")

if changed:
    # Write beside the store and move it into place whole.
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(STORE))
    with os.fdopen(fd, "wb") as f:
        plistlib.dump(store, f, fmt=plistlib.FMT_BINARY)
    os.chmod(tmp, 0o644)
    os.replace(tmp, STORE)
    subprocess.run(["killall", "WallpaperAgent"], check=False)
