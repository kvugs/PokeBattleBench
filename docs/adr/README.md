# Architecture decision records

An ADR captures one architecture-level decision: something that changes module
boundaries, the data model, or the shape of the system.
Anything lighter - a tool choice, a convention, a small tradeoff - goes in
[../decisions.md](../decisions.md) instead, as ten lines.

## How to add one

1. Copy [`0000-template.md`](0000-template.md) to `NNNN-short-title.md`, where
   `NNNN` is the next unused number.
2. Fill it in. Aim for one page. If it needs more, the decision is probably two
   decisions.
3. Open it as a PR and link it from the **Architecture impact** section of the
   pull request.

## Rules

- **Numbers are never reused, and records are never deleted.** A decision that
  turns out wrong gets a new ADR that supersedes it; the old one stays, with its
  status changed to `Superseded by NNNN`. The history of what we believed is
  worth as much as the current answer.
- **Write it when the decision is made, not after it ships.** An ADR written
  retroactively records the justification, not the reasoning.
- **One decision per record.**

## Index

| # | Title | Status |
|---|---|---|
| 0001 | [Use a local Pokémon Showdown server for MVP battles](0001-use-a-local-pokemon-showdown-server.md) | Accepted |
| 0002 | [Build the agent client library before adopting `poke-env`](0002-build-the-agent-client-library.md) | Accepted |
| 0003 | [Use `dev` as the persistent integration branch](0003-use-dev-as-the-integration-branch.md) | Accepted |
