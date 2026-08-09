# Development workflow

## Branch roles

`main` is the GitHub default branch and records stable checkpoints.
`dev` is the persistent integration branch and contains the latest accepted development work.
Feature branches are temporary and start from `dev`.

```text
feature branch --squash PR--> dev --merge-commit PR--> main
                                      ^
hotfix or security PR --> main -------| backport PR
```

Neither shared branch accepts direct commits, force pushes, or deletion.
Both require a pull request, deterministic CI, and resolved review conversations.
Neither requires another collaborator's approval.

## Feature work

Start every ordinary change from the latest `dev`:

```bash
git fetch origin
git switch dev
git pull --ff-only
git switch -c feat/short-description
```

Open the PR into `dev` and squash-merge it after required CI passes.
Strict status checks require the feature branch to contain the latest `dev` before merging.
Delete the feature branch after merge.

## Stable checkpoints

Open one PR from `dev` into `main` when the team decides the integrated state is a stable checkpoint.
Run `just ci` before opening it and inspect all advisory checks before merging.
Use a merge commit so Git preserves which `dev` commits were promoted and later release PRs contain only new work.

The `main` ruleset uses non-strict required checks because persistent `dev` does not contain the merge commit created by the previous promotion.
GitHub Actions still tests the proposed combined result for the release PR.
The required `branch-flow` check rejects ordinary PRs into `main`.

A checkpoint does not need a version tag.
When the team calls a checkpoint a release, create its tag and GitHub Release explicitly from the resulting `main` merge commit.

## Hotfixes and security updates

Prefer the normal `dev` to `main` path whenever the situation permits it.
A `hotfix/*` branch may target `main` when a stable checkpoint needs an urgent correction while `dev` contains work that is not ready to promote.
Dependabot security updates also target `main` because GitHub always sends them to the default branch.

Every direct change to `main` creates an immediate backport obligation:

1. Merge the `hotfix/*` or Dependabot security PR into `main` using a merge commit.
2. Create a new `backport/*` branch from `dev`.
3. Cherry-pick or reapply the patch without copying the `main` merge commit.
4. Open a normal squash-merged PR from `backport/*` into `dev`.
5. Link the two PRs so future readers can verify both branches contain the fix.

Do not merge `main` back into `dev` because `dev` requires linear history.

## Automated dependency updates

Dependabot version updates target `dev`.
Eligible development-tool minor and patch updates may auto-merge into `dev` after required checks pass.
Other version updates wait for normal human review.

Dependabot security updates target default-branch `main` regardless of `target-branch` configuration.
Treat each merged security update as a hotfix and backport it to `dev`.

## CI placement

| Event | Required deterministic CI | Advisory checks | Branch-flow policy |
|---|---|---|---|
| PR into `dev` | Yes | Yes | Runs and permits the target |
| Push after merge to `dev` | Yes | Yes | Not applicable |
| PR from `dev` into `main` | Yes | Yes | Required and permits release |
| `hotfix/*` or Dependabot security PR into `main` | Yes | Yes | Required and permits exception |
| Other PR into `main` | Runs | Runs | Required and rejects the PR |
| Push after merge to `main` | Yes | Yes | Not applicable |
| Nightly schedule | Not applicable | Runs against default-branch `main` | Not applicable |

The required jobs are `template`, `lint`, `types`, `test-fast`, and `package`.
External tests, coverage, dependency auditing, link checking, Trivy, CodeQL, and issue-link reporting remain advisory because their results can depend on systems outside the repository or are informational by design.

## One-time migration after the bootstrap PR

The workflow PR must merge into `main` under the old single-branch rules before `dev` exists.
After it merges, a repository administrator runs:

```bash
git switch main
git pull --ff-only
./scripts/setup-repo.sh
git fetch origin
git switch --track origin/dev
```

The setup script performs the live GitHub changes in this order:

1. Enable squash merges and merge commits while keeping rebase merges disabled.
2. Create `dev` from the current `main` commit if it does not exist.
3. Update `protect-main` from `.github/rulesets/main.json`.
4. Create or update `protect-dev` from `.github/rulesets/dev.json`.

The script keeps `main` as the default branch.
Review the resulting settings at `https://github.com/OWNER/REPOSITORY/settings/rules`.

## Migration verification

Verify all of the following before treating the migration as complete:

1. The repository default branch is still `main`.
2. `dev` points to the bootstrap merge when first created.
3. Direct pushes and deletion are blocked on both shared branches.
4. A feature PR into `dev` requires current CI and offers only squash merge.
5. A release PR from `dev` into `main` requires CI and offers only merge commit.
6. An ordinary feature branch targeting `main` fails `branch-flow`.
7. A `hotfix/*` branch targeting `main` passes `branch-flow` and documents its backport.
8. Dependabot version-update PRs target `dev`.

## Rollback

If verification fails, do not rewrite either shared branch.
Keep the existing `protect-main` ruleset active, disable `protect-dev`, and temporarily direct new work to `main` under the previous PR-only process.
Correct the version-controlled configuration through a focused PR before rerunning the setup script.
