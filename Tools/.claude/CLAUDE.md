# NedcloarBR — Developer Profile

## About

Brazilian developer. Environment: WSL2 (Ubuntu), zsh + Powerlevel10k, Nerd Fonts.
GitHub: NedcloarBR

Machine-specific context (personal vs. work) lives in `~/.claude/machine.md`, imported at the end of this file.

## Stack

- **Language**: TypeScript (strict), Node.js
- **Framework**: NestJS
- **Formatter/Linter**: Biome — custom config at `@nedcloarbr/biome-config`. Never suggest Prettier or ESLint unless the project has its own lint/format configuration.
- **Package manager**: pnpm by default; always follow the repo's lockfile (yarn.lock → yarn, package-lock.json → npm)
- **Infra**: Docker, docker-compose
- **Testing**: Jest (via NestJS)
- **VCS**: Git; hosting per machine (see `machine.md`)

## Tooling

- Bash commands are rewritten to `rtk <cmd>` by a hook, which compresses their output; when the full raw output matters (debugging a failure, exact diffs), run `rtk bypass <cmd>`

## Code Preferences

- TypeScript strict mode always enabled
- Small, focused functions; avoid large monolithic classes
- No comments unless the logic has a non-obvious constraint or invariant
- No `any` without explicit justification; prefer `unknown` with type guards
- `const` by default; immutability where possible
- Imports ordered: external → internal → relative
- No dead code, no unused variables

## Commits

- Conventional Commits: `type(scope): description`
- **Language**: English
- **Types**: `feat`, `fix`, `chore`, `refactor`, `style`, `docs`, `test`, `perf`, `ci`
- **Scope**: module or feature name (e.g., `feat(auth): add JWT refresh`)
- Imperative mood, max 72 characters
- Never use `--no-verify`

## Context & Memory

- Project facts (architecture, commands, conventions) belong in the repo's `CLAUDE.md` or `.claude/rules/`, not in auto memory
- Use auto memory only for in-flight work, gotchas and my feedback; when a memory has stayed true for weeks, propose promoting it to `CLAUDE.md`
- Before trusting a memory that names a file, function or flag, verify it still exists
- Never write company code, credentials or internal details into this global file or the dotfiles repo

## Communication

- Respond in Portuguese (pt-BR)
- Direct and concise — no filler sentences
- Code first; explain only what is non-obvious
- Do not summarize what was done at the end of a response

@~/.claude/machine.md
