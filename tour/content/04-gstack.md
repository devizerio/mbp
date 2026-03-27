# gstack — agent skills platform

**Slash commands that turn Claude Code into a full engineering team.**

gstack is a library of "skills" — structured workflows that run inside
Claude Code. Each skill is a markdown file with embedded shell commands
and decision logic. They're open, readable, and hackable.

## Where it lives

  ~/.claude/skills/gstack/

## Key skills

  /ship              — version bump, changelog, commit, PR
  /office-hours      — YC-style product design brainstorming
  /plan-eng-review   — architecture & test coverage review
  /review            — pre-land diff review (SQL, security, logic)
  /investigate       — systematic debugging with root cause analysis
  /retro             — weekly retrospective from git history
  /qa                — headless browser QA with auto-fix
  /codex             — OpenAI Codex second opinion
  /design-review     — visual design audit with screenshots

## Using skills

Inside any Claude Code session:

  /ship
  /office-hours Build me a Stripe billing integration
  /review
  /investigate why are these tests failing

## Staying current

gstack self-updates. You'll be notified when a new version is available
at the start of any session. To upgrade manually:

  /gstack-upgrade

## The philosophy

Skills follow the Boil the Lake principle: AI makes the marginal cost
of completeness near-zero. Do the complete thing — full test coverage,
all edge cases, proper error handling.
