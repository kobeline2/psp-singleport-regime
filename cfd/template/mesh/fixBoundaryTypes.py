#!/usr/bin/env python3
"""Fix OpenFOAM boundary patch types after gmshToFoam.

This changes only the polyMesh boundary type entries:
- walls       -> wall
- inletOutlet -> patch
- atmosphere -> patch
"""
from pathlib import Path
import re

boundary = Path("constant/polyMesh/boundary")
if not boundary.exists():
    raise SystemExit("constant/polyMesh/boundary not found. Run gmshToFoam first.")

text = boundary.read_text()

def set_type(text, patch, new_type):
    pattern = re.compile(rf"(\n\s*{re.escape(patch)}\s*\n\s*\{{.*?\n\s*type\s+)\w+(\s*;)", re.S)
    new_text, n = pattern.subn(rf"\1{new_type}\2", text, count=1)
    if n == 0:
        print(f"WARNING: patch '{patch}' not found or type entry not changed")
    else:
        print(f"{patch}: type -> {new_type}")
    return new_text

text = set_type(text, "walls", "wall")
text = set_type(text, "inletOutlet", "patch")
text = set_type(text, "atmosphere", "patch")
boundary.write_text(text)
