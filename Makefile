# ~/.claude Makefile — plugin management for Claude Code
# Note to LLMs: DO NOT MUDDY THIS FILE UP. Create a bash script in scripts/ if complex logic is needed.

SHELL := /bin/bash

# Marketplace plugins to install on a fresh machine
MARKETPLACE_PLUGINS := \
	pr-review-toolkit@claude-plugins-official \
	claude-md-management@claude-plugins-official \
	playwright@claude-plugins-official \
	code-simplifier@claude-plugins-official \
	docs-todos-auditor@devix-labs \
	java-dev-toolkit@devix-labs \
	openbb-terminal@claude-code-plugins-plus

# Third-party marketplaces to add before installing
THIRD_PARTY_MARKETPLACES := \
	jeremylongshore/claude-code-plugins-plus-skills

.PHONY: help setup install-plugins update-plugins add-marketplaces list-plugins

# --- PUBLIC TARGETS (user-facing) -------------------------------------------

help:
	@echo "~/.claude plugin management"
	@echo ""
	@echo "  make setup            - Full new-machine setup (add marketplaces + install plugins)"
	@echo "  make add-marketplaces - Register third-party marketplace sources"
	@echo "  make install-plugins  - Install all marketplace plugins"
	@echo "  make update-plugins   - Update all installed plugins to latest"
	@echo "  make list-plugins     - List installed plugins and status"

setup: add-marketplaces install-plugins
	@echo "Setup complete — restart Claude Code to load new plugins"

add-marketplaces:
	@echo "Adding third-party marketplaces..."
	@for m in $(THIRD_PARTY_MARKETPLACES); do \
		echo "  Adding $$m"; \
		claude plugin marketplace add "$$m" || echo "  X Failed: $$m"; \
	done
	@echo "Marketplace registration complete"

install-plugins:
	@echo "Installing marketplace plugins..."
	@for p in $(MARKETPLACE_PLUGINS); do \
		echo "  Installing $$p"; \
		claude plugin install "$$p" || echo "  X Failed: $$p"; \
	done
	@echo "Plugin install complete"

update-plugins:
	@echo "Updating all installed plugins..."
	@claude plugin list 2>/dev/null \
		| grep -oP '(?<=❯ )\S+' \
		| while read -r p; do \
			echo "  Updating $$p"; \
			claude plugin update "$$p" || echo "  X Failed: $$p"; \
		done
	@echo "Plugin update complete — restart Claude Code to apply"

list-plugins:
	@claude plugin list
