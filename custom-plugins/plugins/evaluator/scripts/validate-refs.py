#!/usr/bin/env python3
"""Validates all JSON blocks in reference markdown files."""
import sys
import os
import re
import json

refs_dir = sys.argv[1]
failed = False
for fname in sorted(os.listdir(refs_dir)):
    if not fname.endswith('.md'):
        continue
    content = open(os.path.join(refs_dir, fname)).read()
    blocks = re.findall(r'```json\n(.*?)\n```', content, re.DOTALL)
    for i, block in enumerate(blocks):
        try:
            json.loads(block)
            print(f"PASS: {fname} JSON block {i+1}")
        except json.JSONDecodeError as e:
            print(f"FAIL: {fname} JSON block {i+1}: {e}")
            failed = True

if failed:
    sys.exit(1)
print("PASS: all JSON blocks valid")
