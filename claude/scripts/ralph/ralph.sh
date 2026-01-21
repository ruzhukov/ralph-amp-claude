#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop (Claude Code version)
# Usage: ./ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Find claude binary (check common locations since aliases don't work in scripts)
CLAUDE_BIN="${CLAUDE_BIN:-}"
if [ -z "$CLAUDE_BIN" ]; then
  if command -v claude &> /dev/null; then
    CLAUDE_BIN="claude"
  elif [ -x "$HOME/.claude/local/claude" ]; then
    CLAUDE_BIN="$HOME/.claude/local/claude"
  elif [ -x "$HOME/.local/bin/claude" ]; then
    CLAUDE_BIN="$HOME/.local/bin/claude"
  elif [ -x "/usr/local/bin/claude" ]; then
    CLAUDE_BIN="/usr/local/bin/claude"
  else
    echo "Error: 'claude' command not found. Please install Claude Code CLI."
    echo "See: https://docs.anthropic.com/en/docs/claude-code"
    echo "Or set CLAUDE_BIN environment variable to the path of the claude binary."
    exit 1
  fi
fi
echo "Using claude binary: $CLAUDE_BIN"

# Check if CLAUDE.md exists
if [ ! -f "$SCRIPT_DIR/CLAUDE.md" ]; then
  echo "Error: $SCRIPT_DIR/CLAUDE.md not found."
  exit 1
fi

# Check if prd.json exists
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: $PRD_FILE not found. Run /ralph to create it from a PRD."
  exit 1
fi

echo "Starting Ralph (Claude Code) - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"

  # Run Claude Code with the ralph prompt in non-interactive mode
  # --dangerously-skip-permissions skips all permission prompts (equivalent to amp --dangerously-allow-all)
  # -p runs in non-interactive/print mode
  OUTPUT=$(cat "$SCRIPT_DIR/CLAUDE.md" | "$CLAUDE_BIN" -p --dangerously-skip-permissions 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
