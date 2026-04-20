#!/usr/bin/env python3
"""Validates SKILL.md frontmatter fields."""
import sys
import re

content = open(sys.argv[1]).read()
fm = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if not fm:
    print("FAIL: no frontmatter in SKILL.md")
    sys.exit(1)
body = fm.group(1)
failed = False
for field in ['name:', 'description:', 'tools:']:
    if field not in body:
        print(f"FAIL: missing frontmatter field: {field}")
        failed = True
if failed:
    sys.exit(1)
print("PASS: SKILL.md frontmatter valid")
