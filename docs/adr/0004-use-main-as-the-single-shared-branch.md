# 0004 - Use `main` as the single shared branch

- **Status:** Accepted
- **Date:** 2026-08-12
- **Deciders:** PokeBattleBench collaborators

## Context

ADR 0003 introduced a persistent `dev` integration branch while keeping `main` as the default release branch.
Ordinary changes entered `dev`, then periodic merge commits promoted its accumulated state to `main`.
This split required two rulesets, two merge strategies, a custom branch-direction workflow, backport procedures, and branch-specific automation.
It also moved ordinary pull requests away from the default branch, which caused default-branch-oriented services such as the configured CodeRabbit review integration to skip those pull requests.
The repository is small enough that accepted changes do not need a separate integration queue before becoming the next releasable state.

## Decision

Use `main` as the default and only persistent shared branch.
Create every feature, fix, documentation, and maintenance branch from the latest `main` and open its pull request back to `main`.
Squash-merge accepted pull requests so each atomic change produces one commit in the shared history.
Require pull requests, resolved conversations, strict deterministic status checks, and linear history while keeping the approval count at zero for solo maintainability.
Use tags and GitHub Releases to mark released states instead of maintaining a separate release branch.
Retire `dev` only after its final tip is reachable from `main`, without rewriting either branch.

## Consequences

GitHub Actions, Dependabot, review integrations, scheduled jobs, and contributors all use the default branch without branch-specific routing.
The repository no longer needs a branch-direction check, a second ruleset, release merge commits, or backports between persistent branches.
Every accepted pull request immediately becomes part of the next releasable state on `main`.
Release stability is represented by immutable tags and releases rather than by delaying accepted commits on another branch.
Historical merge commits created by the earlier workflow remain intact, while the linear-history rule governs future changes.

## Alternatives considered

| Option | Why not |
|---|---|
| Keep the persistent `dev` integration branch | Its additional rules, promotion steps, and service configuration do not provide enough value for the current repository. |
| Make `dev` the default branch | It would improve default-branch integrations but retain two persistent branches and the promotion process. |
| Keep `main` release-only and add more integration configuration | Additional configuration would treat the symptoms while preserving the unnecessary branch split. |
| Rewrite branch history into one linear sequence | Rewriting shared history would create avoidable recovery risk and invalidate existing commit references. |
