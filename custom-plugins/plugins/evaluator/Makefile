# evaluator plugin Makefile
# Validates the plugin's own files are correct.

SHELL := /bin/bash
PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REFS := $(PLUGIN_DIR)skills/evaluate/references

.PHONY: check test smoke verify all _validate_structure

all: _validate_structure check test smoke verify

check:
	@echo "==> check: validating JSON and file structure"
	@jq empty "$(PLUGIN_DIR).claude-plugin/plugin.json" \
		|| { echo "FAIL: plugin.json invalid JSON"; exit 1; }
	@jq -e '.name == "evaluator"' "$(PLUGIN_DIR).claude-plugin/plugin.json" > /dev/null \
		|| { echo "FAIL: plugin name mismatch"; exit 1; }
	@for ref in handoff-schema retry-protocol makefile-checks completeness-criteria; do \
		test -f "$(REFS)/$${ref}.md" || { echo "FAIL: missing reference: $${ref}.md"; exit 1; }; \
	done
	@test -f "$(PLUGIN_DIR)skills/evaluate/SKILL.md" \
		|| { echo "FAIL: SKILL.md missing"; exit 1; }
	@echo "PASS: check"

test:
	@echo "==> test: validating JSON blocks in reference files"
	@python3 "$(PLUGIN_DIR)scripts/validate-refs.py" "$(REFS)"
	@echo "==> test: validating SKILL.md frontmatter"
	@python3 "$(PLUGIN_DIR)scripts/validate-skill.py" "$(PLUGIN_DIR)skills/evaluate/SKILL.md"
	@echo "PASS: test"

smoke:
	@echo "==> smoke: verifying plugin discovery"
	@test -f "$(PLUGIN_DIR).claude-plugin/plugin.json" \
		|| { echo "FAIL: plugin.json not found at expected path"; exit 1; }
	@test -f "$(PLUGIN_DIR)skills/evaluate/SKILL.md" \
		|| { echo "FAIL: SKILL.md not found at expected path"; exit 1; }
	@echo "Plugin files present at correct paths."
	@echo "PASS: smoke"

verify:
	@echo "==> verify: cross-referencing SKILL.md against reference files"
	@for ref in handoff-schema retry-protocol makefile-checks completeness-criteria; do \
		grep -q "$$ref" "$(PLUGIN_DIR)skills/evaluate/SKILL.md" \
			|| { echo "FAIL: SKILL.md does not reference: $$ref"; exit 1; }; \
	done
	@for kw in "auto-FAIL" "Makefile Gate" "Completeness" "sink"; do \
		grep -q "$$kw" "$(PLUGIN_DIR)skills/evaluate/SKILL.md" \
			|| { echo "FAIL: SKILL.md missing section: $$kw"; exit 1; }; \
	done
	@echo "PASS: verify"

_validate_structure:
	@for f in \
		".claude-plugin/plugin.json" \
		"skills/evaluate/SKILL.md" \
		"skills/evaluate/references/handoff-schema.md" \
		"skills/evaluate/references/retry-protocol.md" \
		"skills/evaluate/references/makefile-checks.md" \
		"skills/evaluate/references/completeness-criteria.md"; do \
		test -f "$(PLUGIN_DIR)$$f" \
			|| { echo "FAIL: missing file: $$f"; exit 1; }; \
	done
