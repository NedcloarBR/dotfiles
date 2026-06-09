# NedcloarBR — Developer Profile

## About

Brazilian developer. Environment: WSL2 (Ubuntu), zsh + Powerlevel10k, Nerd Fonts.
GitHub: NedcloarBR

## Stack

- **Language**: TypeScript (strict), Node.js
- **Framework**: NestJS
- **Formatter/Linter**: Biome — custom config at `@nedcloarbr/biome-config`. Never suggest Prettier or ESLint unless the project has its own lint/format configuration.
- **Package manager**: pnpm (default), yarn (N-D-B project)
- **Infra**: Docker, docker-compose
- **Testing**: Jest (via NestJS)
- **VCS**: Git + GitHub

## Active Projects

- **N-D-B**: Discord bot built with NestJS + TypeScript + Yarn
- **nestjs-toolkit / nestjs-initializr**: NestJS tooling
- **biome-config**: shared Biome configuration across projects
- **dotfiles**: personal machine setup (zsh, aliases, tools)

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

## Communication

- Respond in Portuguese (pt-BR)
- Direct and concise — no filler sentences
- Code first; explain only what is non-obvious
- Do not summarize what was done at the end of a response
