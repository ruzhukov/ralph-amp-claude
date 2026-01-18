# Ralph Agent Instructions (Claude Code)

## Overview

Ralph is an autonomous AI agent loop that runs Claude Code repeatedly until all PRD items are complete. Each iteration is a fresh Claude Code instance with clean context.

## Commands

```bash
# Run Ralph
./scripts/ralph/ralph.sh [max_iterations]

# Check story status
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# View progress log
cat scripts/ralph/progress.txt
```

## Key Files

- `scripts/ralph/ralph.sh` - The bash loop that spawns fresh Claude Code instances
- `scripts/ralph/prompt.md` - Instructions given to each Claude Code instance
- `scripts/ralph/prd.json` - User stories with `passes` status (created by ralph skill)
- `scripts/ralph/prd.json.example` - Example PRD format
- `scripts/ralph/progress.txt` - Append-only learnings for future iterations
- `.claude/skills/prd/` - Skill for generating PRDs
- `.claude/skills/ralph/` - Skill for converting PRDs to JSON

## Skills

Use `/prd` to create a PRD for a new feature. Use `/ralph` to convert a PRD to prd.json format.

## Patterns

- Each iteration spawns a fresh Claude Code instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Always update CLAUDE.md with discovered patterns for future iterations
- UI stories must include browser verification via Playwright MCP
