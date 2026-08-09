# PokeBattleBench

A laboratory where increasingly capable Pokémon AIs can be created, tested, understood, and challenged.

[![CI](https://github.com/kvugs/pokebattlebench/actions/workflows/ci.yml/badge.svg)](https://github.com/kvugs/pokebattlebench/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/python-3.14%2B-blue)](https://www.python.org/downloads/)
[![uv](https://img.shields.io/badge/deps-uv-261230)](https://docs.astral.sh/uv/)
[![Ruff](https://img.shields.io/badge/style-ruff-D7FF64)](https://docs.astral.sh/ruff/)

> **Status:** under construction 👷

## For contributors

New here? Read **[CONTRIBUTING.md](CONTRIBUTING.md)** - it's a one-pager. The
60-second version:

```bash
just install                # once: locked deps + git hooks
just ci                     # before pushing: lint + types + fast tests + built artifacts
```

Pick an issue, use a Conventional Commit message such as `feat: add export`,
open a focused PR with the same title shape, and squash-merge once required CI
is green. Ask for review when a friend is available; the default rules
intentionally keep solo projects operable without a second account.

Run `just` with no arguments to list every recipe. The
[`Justfile`](Justfile) documents when each one is meant to be run. Use
`just links` for the advisory external-link check.

When maintaining the template repository itself, keep placeholders intact and
run `just template-ci`; it materializes and verifies a disposable copy.

## Important reference files and folders

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - how to set up and open PRs.
- **[AGENTS.md](AGENTS.md)** - rules written by humans for AI coding agents.
- **[SECURITY.md](SECURITY.md)** - how to report a vulnerability privately.
- **[docs/development-workflow.md](docs/development-workflow.md)** - how feature, release, hotfix, and dependency PRs move between branches.
- **[docs/project-direction.md](docs/project-direction.md)** - the agreed learning direction and MVP scope.
- **[docs/decisions.md](docs/decisions.md)** - the lightweight decision log.
- **[docs/adr/](docs/adr/)** - architecture decision records (the heavier, numbered decisions).
