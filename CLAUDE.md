# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Ralph?

Ralph is an autonomous AI agent loop that runs an AI coding assistant repeatedly until all PRD items are complete. Each iteration spawns a fresh instance with clean context. Memory persists only via git history, `progress.txt`, and `prd.json`.

## Two Versions

| Version | Location | AI Tool | Command |
|---------|----------|---------|---------|
| Amp | Root (`./`) | [Amp](https://ampcode.com) | `./ralph.sh` |
| Claude Code | `claude/` | [Claude Code](https://claude.ai/code) | `./claude/scripts/ralph/ralph.sh` |

## Commands

```bash
# Run Ralph with Amp (original)
./ralph.sh [max_iterations]

# Run Ralph with Claude Code
./claude/scripts/ralph/ralph.sh [max_iterations]

# Flowchart visualization
cd flowchart && npm install && npm run dev   # Dev server
cd flowchart && npm run build                # Build
cd flowchart && npm run lint                 # Lint
```

## Architecture

### Core Loop
1. Archives previous run if branch changed
2. Reads `prompt.md` and pipes to AI tool
   - Amp: `amp --dangerously-allow-all`
   - Claude Code: `claude -p --dangerously-skip-permissions`
3. Checks for `<promise>COMPLETE</promise>` signal to exit
4. Repeats until all stories pass or max iterations reached

### Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | Bash loop spawning fresh AI instances |
| `prompt.md` | Instructions for each iteration |
| `prd.json` | User stories with `passes` status |
| `prd.json.example` | Example PRD format |
| `progress.txt` | Append-only learnings between iterations |

### Skills

**Amp:** Located in `skills/`. Install globally with:
```bash
cp -r skills/prd ~/.config/amp/skills/
cp -r skills/ralph ~/.config/amp/skills/
```

**Claude Code:** Located in `claude/.claude/skills/`. Auto-discovered when you copy `claude/` contents to your project.

### Flowchart (`flowchart/`)
Interactive React Flow visualization deployed to GitHub Pages. Built with Vite, React 19, TypeScript.

## Critical Concepts

**Each iteration = fresh context.** The only memory between iterations is git history, `progress.txt`, and `prd.json`.

**Stories must be small.** Each PRD item should complete in one context window. If too big, split it.

**Dependency ordering matters.** Stories execute by priority number. Schema → backend → UI.

**Acceptance criteria must be verifiable.** "Works correctly" is bad. "Button shows confirmation dialog" is good.

**UI stories require browser verification.** Include "Verify in browser" in acceptance criteria.

**CLAUDE.md/AGENTS.md updates are key.** After each iteration, update relevant instruction files with discovered patterns for future iterations.

## PRD JSON Format

```json
{
  "project": "ProjectName",
  "branchName": "ralph/feature-name",
  "description": "Feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": ["Criterion 1", "Typecheck passes"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## Workflow

1. Create PRD: Use prd skill → generates `tasks/prd-[feature].md`
2. Convert to JSON: Use ralph skill → generates `prd.json`
3. Run: `./ralph.sh` (or `./claude/scripts/ralph/ralph.sh`) until complete
