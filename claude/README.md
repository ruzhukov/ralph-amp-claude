# Ralph (Claude Code Version)

![Ralph](../ralph.webp)

Ralph is an autonomous AI agent loop that runs [Claude Code](https://claude.ai/code) repeatedly until all PRD items are complete. Each iteration is a fresh Claude Code instance with clean context. Memory persists via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- `jq` installed (`brew install jq` on macOS)
- A git repository for your project

## Setup

```bash
# From your project root
cp -a /path/to/ralph/claude/. .
chmod +x scripts/ralph/ralph.sh
```

## Workflow

### 1. Create a PRD

Use the PRD skill to generate a detailed requirements document:

```
Use the prd skill to create a PRD for [your feature description]
```

Answer the clarifying questions. The skill saves output to `tasks/prd-[feature-name].md`.

### 2. Convert PRD to Ralph format

Use the Ralph skill to convert the markdown PRD to JSON:

```
Use the ralph skill to convert tasks/prd-[feature-name].md to prd.json
```

This creates `prd.json` with user stories structured for autonomous execution.

### 3. Run Ralph

```bash
./scripts/ralph/ralph.sh [max_iterations]
```

Default is 10 iterations.

Ralph will:
1. Create a feature branch (from PRD `branchName`)
2. Pick the highest priority story where `passes: false`
3. Implement that single story
4. Run quality checks (typecheck, tests)
5. Commit if checks pass
6. Update `prd.json` to mark story as `passes: true`
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

## Key Files

| File | Purpose |
|------|---------|
| `scripts/ralph/ralph.sh` | The bash loop that spawns fresh Claude Code instances |
| `scripts/ralph/prompt.md` | Instructions given to each Claude Code instance |
| `scripts/ralph/prd.json` | User stories with `passes` status (the task list) |
| `scripts/ralph/prd.json.example` | Example PRD format for reference |
| `scripts/ralph/progress.txt` | Append-only learnings for future iterations |
| `.claude/skills/prd/` | Skill for generating PRDs |
| `.claude/skills/ralph/` | Skill for converting PRDs to JSON |

## Critical Concepts

### Each Iteration = Fresh Context

Each iteration spawns a **new Claude Code instance** with clean context. The only memory between iterations is:
- Git history (commits from previous iterations)
- `progress.txt` (learnings and context)
- `prd.json` (which stories are done)

### Small Tasks

Each PRD item should be small enough to complete in one context window. If a task is too big, the LLM runs out of context before finishing and produces poor code.

Right-sized stories:
- Add a database column and migration
- Add a UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

Too big (split these):
- "Build the entire dashboard"
- "Add authentication"
- "Refactor the API"

### CLAUDE.md Updates Are Critical

After each iteration, Ralph updates the relevant `CLAUDE.md` files with learnings. This is key because Claude Code automatically reads these files, so future iterations (and future human developers) benefit from discovered patterns, gotchas, and conventions.

Examples of what to add to CLAUDE.md:
- Patterns discovered ("this codebase uses X for Y")
- Gotchas ("do not forget to update Z when changing W")
- Useful context ("the settings panel is in component X")

### Feedback Loops

Ralph only works if there are feedback loops:
- Typecheck catches type errors
- Tests verify behavior
- CI must stay green (broken code compounds across iterations)

### Browser Verification for UI Stories

Frontend stories must include "Verify in browser" in acceptance criteria. Ralph will use browser automation (Playwright MCP or similar) to navigate to the page, interact with the UI, and confirm changes work.

### Stop Condition

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>` and the loop exits.

## Debugging

Check current state:

```bash
# See which stories are done
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from previous iterations
cat scripts/ralph/progress.txt

# Check git history
git log --oneline -10
```

## Customizing prompt.md

Edit `scripts/ralph/prompt.md` to customize Ralph's behavior for your project:
- Add project-specific quality check commands
- Include codebase conventions
- Add common gotchas for your stack

## Archiving

Ralph automatically archives previous runs when you start a new feature (different `branchName`). Archives are saved to `archive/YYYY-MM-DD-feature-name/`.

## CLI Reference

The main script uses these Claude Code CLI flags:

| Flag | Purpose |
|------|---------|
| `-p` | Non-interactive/print mode (headless execution) |
| `--dangerously-skip-permissions` | Skip all permission prompts |

For more controlled execution, you can modify `ralph.sh` to use:
- `--allowedTools "Bash,Read,Edit,Write"` - Allow specific tools only
- `--max-turns N` - Limit agent turns per iteration
- `--output-format json` - Get structured output

## References

- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Geoffrey Huntley's Ralph article](https://ghuntley.com/ralph/)
