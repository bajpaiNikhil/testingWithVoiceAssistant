# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Project AI Rules

Architecture:
This repository uses feature-based modules.

Context hierarchy:
Root → Module → Feature

Rules:
- Each module has its own CLAUDE.md
- Each feature has its own CLAUDE.md
- Each feature contains plan.md and context.md
- Never modify architecture without updating CLAUDE.md

Feature structure:

feature/
  CLAUDE.md
  plan.md
  context.md
