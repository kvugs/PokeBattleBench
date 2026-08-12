# Decision log

Append-only. When we make a non-obvious call, add ~10 lines to the **top** of the list below.
No template, no ceremony.
The goal is simple: months from now, nobody has to reconstruct "why did we do this?"

**When to log here vs. an ADR:** anything lighter than an architecture decision goes here (tools, conventions, small tradeoffs).
Architecture-level decisions - ones that change module boundaries, data models, or how the system is shaped - get a numbered record in [adr/](adr/) instead.
When in doubt, a 10-line entry here, explaining the when, the what, the why, and the result, is always fine.

The entries below record decisions made in the template itself. Keep them as
provenance; add project-specific decisions above them.

---

## 2026-08-12 - Bootstrap Lychee directly from verified release binaries

**What:** Replace Lychee's remote pre-commit environment with a local hook backed by `scripts/setup-lychee.sh`.
Download the pinned official binary with bounded retries, verify its release checksum, and cache it per version and platform.

**Why:** The upstream hook first downloads `cargo-binstall`, then asks it to download Lychee, so either service can fail before links are checked.
Its source-build fallback is also incompatible with the install path pre-commit requests.

**Result:** Local and CI link checks share one deterministic bootstrap, repeated checks reuse the verified binary, and CI reports bootstrap and link failures in separate steps.
This supersedes the manual remote-hook pin recorded on 2026-07-30 while preserving that entry as history.

## 2026-08-12 - Treat the uv version as a minimum compatibility claim

**What:** Require `uv >=0.11.31` without an upper bound and remove the dedicated lower-bound CI job.
Keep normal CI pinned to `uv 0.12.0` so required runs remain reproducible.

**Why:** Version `0.11.31` is the oldest release proven to work, but no known incompatibility justifies rejecting future uv releases.
Continuously duplicating the full CI gate at the minimum version adds a required check without protecting against an observed failure mode.

**Result:** Contributors and Dependabot may use any uv release at or above the known minimum, while CI continues to test one deterministic tool version.
This supersedes the bounded range and required lower-bound test chosen on 2026-08-09 while preserving that entry as history.

## 2026-08-11 - Pair host policies in one shared skill directory

**What:** Prefer one canonical skill directory plus a Claude Code discovery symlink, even when the skill needs manual-only invocation.
Put Claude Code's `disable-model-invocation: true` in the shared `SKILL.md` and Codex's equivalent `policy.allow_implicit_invocation: false` in `agents/openai.yaml`.
Reserve adapters for cases where a supported host cannot load the shared source correctly.

**Why:** Codex tolerates the Claude-specific frontmatter extension while reading its own policy sidecar, and Claude Code ignores the Codex sidecar.
Keeping both policies beside one instruction body preserves equivalent behavior without an adapter or duplicated Markdown.

**Result:** The `to-gh-issues` skill is one directory discovered by both harnesses.
This supersedes the adapter preference in the earlier decision below while retaining that entry as historical context.

## 2026-08-11 - Share one skill source across Codex and Claude Code

**What:** Store project skills canonically under `.agents/skills/`, normally link each skill directory into `.claude/skills/`, and link `CLAUDE.md` to `AGENTS.md`.
When a skill needs Claude-only frontmatter, use a minimal Claude adapter that declares and loads the canonical skill instead of copying its instructions.
A required local check verifies instruction links, adapters, and canonical targets.

**Why:** Codex and Claude Code discover repository skills from different directories, but both support directory symlinks and the same `SKILL.md` core format.
Their invocation-control fields differ, so a symlink cannot represent every valid shared skill without one host rejecting the other's frontmatter.
Keeping one authoritative body plus a small adapter prevents provider-specific instructions from drifting while retaining each tool's native discovery and validation rules.

**Result:** Future skills can support both model families from one implementation.

## 2026-08-09 - Test the oldest supported uv release in required CI

**What:** Support `uv >=0.11.31,<0.13` and add a required `uv-lower-bound` job that runs the complete local CI gate with exactly `uv 0.11.31`.
Keep the primary CI jobs on the repository's preferred `uv 0.12` release.

**Why:** GitHub's hosted Dependabot updater uses `uv 0.11.31`, but the previous `>=0.12.0` guard stopped it before dependency updates began.
An isolated test proved that `0.11.31` can sync and regenerate the lockfile, update direct and transitive dependencies, audit the environment, and pass the complete gate before and after an update.

**Result:** Dependabot can maintain Python dependencies against `dev`, contributors retain a bounded tool range, and required CI prevents future changes from silently breaking the supported lower bound.

## 2026-08-09 - Prove the server-connected battle before expanding the laboratory

**What:** Limit the MVP to two project-owned autonomous agents completing one legal battle through a local Pokémon Showdown server.
Defer evaluation suites, scaling, training pipelines, MLOps, advanced agent strategies, and a dedicated UI until that end-to-end flow works.

**Why:** The collaborators first want to learn WebSockets, client-server communication, asynchronous state management, and maintainable module design.
Adding later laboratory layers before the basic battle works would hide these fundamentals behind unrelated complexity and leave every later feature dependent on an unproven boundary.

**Result:** MVP work prioritizes a clean Python client library, legal decisions, clear failure behavior, and one complete battle.
Later work can add evaluation and ML systems against a small, tested agent boundary instead of redesigning the integration around each experiment.

## 2026-08-05 - Keep CodeRabbit assertive but advisory during rollout

**What:** Use CodeRabbit's hosted GitHub App with a repository-owned `.coderabbit.yaml` configuration.
Automatically review non-draft contributor pull requests, skip Dependabot, keep summaries in the walkthrough, and wait up to 15 minutes for existing GitHub checks.

**Why:** An assertive profile matches the repository's engineering standards, while an advisory rollout lets contributors calibrate AI feedback before it can block merging.
Repository-owned settings are visible and reviewable, and the existing CI remains the authority for deterministic lint, type, test, and package gates.

**Result:** Contributors receive consistent reviews without another workflow, dependency, secret, or duplicate Ruff run.
CodeRabbit reads `AGENTS.md` and CI results for context, and `request_changes_workflow` is the single explicit switch to enable only after the team trusts the review signal.

## 2026-08-02 - Label issues by expected focused time

**What:** Atomic issues may receive one of two mutually exclusive estimates: `time:hours` or `time:days`. The setup script creates them, and contributors maintain them manually as scope becomes clearer. Work approaching a focused week is split into atomic sub-issues instead of receiving a larger bucket.

**Why:** Contributors to this hobby project often choose work by the time they can offer. A coarse estimate makes that constraint visible before someone commits to an issue, lowering the cost of starting and reducing abandoned work. “Focused effort” distinguishes the estimate from a deadline or elapsed calendar time.

**Result:** Contributors can filter for work that fits their availability, while the absence of a week-sized label reinforces the repository's atomic-issue convention. Estimates remain deliberately coarse and optional; no automation enforces them, and maintainers update or remove stale estimates during normal issue triage.

## 2026-08-02 - License PokeBattleBench under Apache-2.0

**What:** PokeBattleBench's original code is licensed under Apache-2.0. Third-party code keeps its own license and attribution.

**Why:** Apache-2.0 is permissive while providing an explicit patent grant and clear contribution terms. It is compatible with the MIT-licensed Pokémon Showdown server and simulator, which PokeBattleBench can use without imposing copyleft on its original code. Pokémon Showdown's client is separately licensed under AGPL-3.0, so copying or modifying client code requires preserving those terms or obtaining separate permission.

**Result:** Contributors and users have clear rights to use, modify, and redistribute PokeBattleBench. Any incorporated Showdown code must remain identified under its upstream license, and this license does not grant rights to Pokémon trademarks or assets.

## 2026-07-30 - Keep Lychee outside Dependabot temporarily

**What:** The pre-commit Dependabot configuration ignores only Lychee. Its immutable `lychee-vX.Y.Z` revision remains pinned in `.pre-commit-config.yaml` and is updated manually; every other remote hook stays Dependabot-managed.

**Why:** Dependabot's pre-commit updater resolves Lychee's release correctly, then crashes internally while comparing the prefixed tag with a numeric version. Retrying cannot repair that deterministic parser error, and replacing the release tag with a mutable alias would weaken reproducibility.

**Result:** Weekly pre-commit update jobs can finish without hiding failures for unrelated hooks. Lychee remains deterministic and advisory, with one explicit manual maintenance exception to remove once Dependabot supports its tag format.

## 2026-07-29 - Separate library compatibility from the tested environment

**What:** Runtime additions now receive lower bounds, development tools remain exact, and `uv.lock` records the complete tested resolution. `just update` temporarily relaxes exact direct requirements, resolves under the project's index and age policy, then writes the chosen versions back.

**Why:** Exact runtime metadata makes a reusable library unnecessarily difficult to install alongside other packages, while a lockfile already gives contributors and CI an exact environment. Tool versions are different: their command-line behavior is part of the repository's development contract. A plain `uv lock --upgrade` could not move those exact declarations, so it gave a misleading impression of updating them.

**Result:** Built libraries advertise compatibility instead of an application lock policy, development behavior remains explicit, and `just update` now updates both direct and transitive dependencies without hand-editing the lockfile.

## 2026-07-29 - Enforce Conventional Commits at commit time

**What:** Added the locked Commitizen client as a `commit-msg` hook and documented the same Conventional Commit shape for PR titles.

**Why:** GitHub uses the PR title for this repository's squash commit, and a single-commit PR commonly starts with that commit's subject. A local check catches vague or malformed subjects at the cheapest point. Gitlint was reconsidered, but its last release and repository activity were in 2023; Commitizen is active, supports Python 3.14, and provides the convention without adding a Node toolchain. The branch-wide pre-push hook remains excluded because intermediate commits are squashed.

**Result:** Local commits and final squash titles share a readable `<type>(<scope>): <description>` convention without requiring every intermediate branch commit to survive in main's history.

## 2026-07-29 - Make hook enforcement explicit and deterministic

**What:** Required CI now runs a full-tree Gitleaks scan, read-only Typos and Markdownlint checks, schema validation for composite actions and issue forms, and cross-platform filesystem checks. Actionlint calls the locked ShellCheck binary through a repository wrapper. Every configured hook is classified as required or intentionally local/advisory.

**Why:** The upstream Gitleaks hook remains staged-only under `--all-files`, Typos writes by default, and actionlint only invokes ShellCheck when it happens to be on `PATH`. Those defaults made local and CI behavior diverge or made a required check scan nothing. Link availability is external, so Lychee belongs in the advisory nightly workflow instead of the merge gate.

**Result:** Required checks report without rewriting files, new hooks cannot silently become local-only, and external failures stay visible through the existing nightly watchdog without blocking merges.

## 2026-07-29 - Umbrella issues get a form, a ☂️ title prefix, and a sync job

**What:** Added `.github/ISSUE_TEMPLATE/umbrella.yml`, the `umbrella` label in `scripts/setup-repo.sh`, and `.github/workflows/issue-hygiene.yml`.
The form pre-fills the `☂️` marker plus a trailing space and applies the label; the workflow keeps the two in step in both directions on `opened`, `edited`, `labeled`, and `unlabeled`.

**Why:** Every other issue in the repository is atomic, and the umbrella is the one deliberate exception, so it has to be identifiable at a glance rather than by opening it.
A label alone is invisible in a list of titles and in a commit message; an emoji alone is a convention people forget.
Requiring both by hand means they drift - typically the label gets added to an existing issue and the title never changes - and a marker that is only usually right is not a marker anyone can filter on.
The job removes the rule instead of enforcing it: set either side, get both.
Edits made with `GITHUB_TOKEN` do not trigger workflow runs, so the sync cannot loop.

**Result:** `☂️` in the title and `label:umbrella` return the same set, and the PR rule "never close an umbrella with one PR" has something concrete to point at.
