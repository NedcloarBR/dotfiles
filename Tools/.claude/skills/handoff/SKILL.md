---
name: handoff
description: Save the current task state to a handoff file so a fresh session can resume it after /clear or compaction
disable-model-invocation: true
argument-hint: "[done | extra notes]"
allowed-tools: Read, Write, Bash(git status *), Bash(git diff *), Bash(git log *), Bash(rm ~/.claude/handoffs/*)
---

Handoff file: !`bash "$HOME/.claude/hooks/handoff-path.sh"`

Arguments: $ARGUMENTS

## If the argument is `done`

Delete the handoff file and reply with one line confirming it. Stop there.

## Otherwise

1. Run `git status --short` and `git diff --stat` to ground the file list in what actually changed.
2. Write the handoff file (overwrite it), following the template below. Fold any extra notes from the arguments into the right section.
3. Reply with the file path and one line suggesting `/clear`. The next session loads the file automatically.

## Template

```markdown
# Handoff: <task in one line>

Updated: <YYYY-MM-DD HH:MM> · Branch: <branch>

## Goal
<What done looks like, in 1–3 lines>

## State
- Done: <what is finished and verified>
- In progress: <what is half-done, and where exactly it stopped>

## Files
- `path/to/file` — <what changed or why it matters>

## Decisions
- <decision> — <why; include rejected alternatives the user ruled out>

## Gotchas
- <errors hit, commands that failed, things that look right but aren't>

## Next steps
1. <the very next concrete action>
```

## Rules

- Write for a reader with zero context: no "as discussed", no references to earlier messages.
- Record facts from this session only; mark anything unverified as such.
- Keep it under ~60 lines. Drop empty sections. Link to files instead of pasting code.
- Never include secrets, tokens or contents of `.env` files.
