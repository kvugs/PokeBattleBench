# 0003 - Use `dev` as the persistent integration branch

- **Status:** Accepted
- **Date:** 2026-08-09
- **Deciders:** PokeBattleBench collaborators

## Context

The collaborators want active development to accumulate separately from stable checkpoints on `main`.
They want feature authors to resolve integration conflicts against a shared development line before a checkpoint reaches `main`.
The repository currently treats `main` as the only protected branch, allows only squash merges, and uses it as the target for automation.
A persistent branch that is repeatedly squash-merged into another branch loses ancestry and causes old commits or conflicts to reappear in later PRs.
GitHub also sends Dependabot security updates only to the default branch, which the team wants to keep as `main`.

## Decision

Keep `main` as the default and stable branch, and use persistent `dev` as the integration branch.
Squash feature PRs into `dev` and promote `dev` into `main` with a merge commit.
Require zero approvals, resolved conversations, and deterministic CI on both branches.
Reject ordinary PRs into `main`, while allowing `dev`, `hotfix/*`, and Dependabot security branches.
Backport every direct `main` change to `dev` through a separate squash-merged PR.

## Consequences

Everyday development has one integration target and one commit per feature PR.
Merge commits on `main` preserve ancestry and mark stable checkpoints, so `main` cannot require linear history.
Release checks on `main` are non-strict because `dev` does not contain previous release merge commits, while CI still evaluates the proposed PR merge.
Keeping `main` as default makes stable code the public repository view but requires contributors to select `dev` deliberately.
Dependabot version updates can target `dev`, while its security updates require direct `main` handling and an immediate backport.
Hotfixes add process overhead, so they remain exceptions rather than a parallel development path.

## Alternatives considered

| Option | Why not |
|---|---|
| Keep one `main` branch | It does not provide the separate integration and checkpoint stages chosen by the collaborators. |
| Make `dev` the default branch | It simplifies contribution defaults but shows development code publicly and moves scheduled and security automation away from stable `main`. |
| Squash `dev` into `main` | Reusing the long-lived head branch would repeat old commits and conflict resolution in later release PRs. |
| Rebase-merge `dev` into `main` | GitHub rewrites commit identities, so the two persistent branches still lose shared ancestry. |
| Reset `dev` after every release | It rewrites a shared branch, disrupts open work, and turns promotion into a destructive operation. |
