# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal utility bin directory containing command-line tools and scripts for development, git operations, and system automation. The scripts are primarily written in bash, Ruby, and Perl, with some Python utilities.

## Script Categories and Architecture

### Git Utilities
- Git workflow enhancement scripts (git-update, git-remove-merged-branches, git-ai-message, etc.)
- Follow the pattern of accepting remote/branch parameters with sensible defaults
- Include error handling with `set -e` in bash scripts
- Support dry-run modes where applicable (use `-n` flag)

### Development Tools  
- Web development utilities (serve, make-bookmarklet, sri-integrity)
- Image processing tools (scale-app-icons, generate-xcode-imageset, retina-scale)
- Data processing scripts (colours.rb for color conversion, progress for piped data)

### System Scripts
- Shell enhancement utilities (hist.rb for command analysis, enable-sudo-touch-id)
- File management tools (find-unused-images, count-chars)

## Common Patterns

### Script Structure
- All executable scripts start with appropriate shebang (`#!/bin/bash`, `#!/usr/bin/env ruby`, etc.)
- Bash scripts use `set -e` for error handling
- Ruby scripts often process STDIN/command line arguments with explicit argument parsing
- Support both piped input and file arguments where relevant

### Argument Handling
- Use `"${1:-default}"` pattern for optional arguments with defaults in bash
- Ruby scripts use ARGV.shift pattern for argument processing
- Include help/usage when arguments are malformed

### Git Script Conventions
- Accept remote name as first argument (default to origin or auto-detect)
- Accept branch name as second argument (default to current branch or master/main)
- Preserve original branch state (stash/unstash, checkout back to original branch)
- Use `git rev-parse --abbrev-ref HEAD` to get current branch

### Data Processing
- Ruby scripts that process data streams use proper buffering and error handling
- Support both byte and line counting modes where applicable
- Use STDERR for progress/status output, STDOUT for data

## Development Workflow

This repository has no build system, package.json, or formal testing framework. Scripts are standalone utilities meant to be:
- Executable from anywhere in the system PATH
- Self-contained with minimal dependencies
- Robust with proper error handling