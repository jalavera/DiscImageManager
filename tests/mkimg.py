#!/usr/bin/env python3
"""Rebuild a test disc image from a .spec file: the first line is the image
size, each further line is an offset and a base64, zlib-compressed chunk."""
import sys, zlib, base64
spec, out = sys.argv[1], sys.argv[2]
with open(spec) as f, open(out, 'wb') as img:
    img.truncate(int(f.readline()))
    for line in f:
        if line.strip():
            off, data = line.split()
            img.seek(int(off))
            img.write(zlib.decompress(base64.b64decode(data)))
