Analyze the current repository state and create a commit following Conventional Commits.

## Steps

1. Run `git status` to check the current state
2. Run `git diff --cached` to see what is staged
3. If nothing is staged, run `git diff` to see unstaged changes and ask the user what should be included before proceeding

## Message format

```
type(scope): short description in English
```

**Types:** `feat`, `fix`, `chore`, `refactor`, `style`, `docs`, `test`, `perf`, `ci`

**Scope:** name of the affected module, feature, or folder (e.g., `auth`, `user`, `docker`, `install`)

**Rules:**
- Message in English
- Description up to 72 characters
- Use imperative mood: "add", "fix", "remove" — not "added", "fixed", "removed"
- If changes span multiple distinct domains, suggest multiple commits

## Execution

Create the commit with:

```bash
git commit -m "$(cat <<'EOF'
type(scope): description
EOF
)"
```

Do not use `--no-verify`. If the pre-commit hook fails, fix the issue before retrying.
