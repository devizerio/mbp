# Claude Code — AI coding assistant

**A terminal-native AI that writes code alongside you.**

Claude Code is Anthropic's agentic coding assistant. It runs directly in
your terminal, understands your entire codebase, and can read files, run
commands, write code, and commit changes — all from a conversation.

## How to use it

  cd ~/Developer/my-project
  claude

That's it. Claude Code reads the project context and starts a session.

## What it can do

  - Read and write files across the project
  - Run shell commands and tests
  - Search the codebase with grep, ripgrep, or AST tools
  - Create git commits with conventional messages
  - Explain code, refactor functions, fix bugs

## CLAUDE.md

Put a `CLAUDE.md` file in any project root. Claude Code reads this
automatically — use it to document architecture decisions, coding
conventions, and recurring tasks. It's AI-readable documentation.

## Skills with gstack

gstack extends Claude Code with slash commands:

  /ship          — bump version, commit, open a PR
  /review        — code review before landing
  /office-hours  — product design session
  /retro         — weekly engineering retrospective
  /investigate   — systematic root-cause debugging

Run `/help` inside a Claude session to see everything available.

## Keyboard shortcuts

  Ctrl+C         — interrupt current action
  /clear         — clear conversation context
  /compact       — summarise and compress history
