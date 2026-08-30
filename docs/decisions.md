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

## 2026-08-30 - The first battle format is `gen3randombattle`

**What:** PokeBattleBench's first supported format is Gen 3, singles, with server-generated random teams, and each agent may read only what its own connection receives.
The format identifier is `gen3randombattle`, advertised by the pinned server as `[Gen 3] Random Battle`.
One challenge produces one battle, because we send no `Best of` rule.
The collaborators took this call in a meeting; it answers the four questions #35 raised.
This is the direction for now, not a permanent constraint.
Any part of it can be revised by a later entry in this log.

**Why:** Gen 3 is small enough to model correctly and large enough to be real.
Abilities, held items, and the physical/special split by move type all exist, so a state tracker built for it is not a toy, while Terastallization, Dynamax, megas, and Z-moves do not.
Singles keeps one decision per `|request|`, so the action space in #36 and the state in #37 stay minimal.
Random teams remove team construction from the MVP. The server builds both teams, so there is no builder, no packed-team encoder, and no rejection path to handle.
Restricting each agent to its own connection is what makes any later result mean anything; an agent that can read its opponent's private state is not measurable.

**Result:** #36, #37, #38, and #40 can name a concrete format instead of deferring to this issue.
We verified this against the pinned server (`SHOWDOWN_COMMIT=d43fb79a049f624c079c387d043ef53f62aed226`) rather than upstream documentation.
Two guest clients challenged and accepted, both entered `battle-gen3randombattle-2` with `|init|battle`, and the room reported `|gametype|singles`, `|gen|3`, and `|tier|[Gen 3] Random Battle`.
No team was sent by either client and no team preview occurred; the first `|request|` arrived directly.
The server's own definition sets `team: 'random'` and no `gameType`, which is why singles and random teams need no extra rules from us.
Two consequences to carry forward.
`HP Percentage Mod` is in the ruleset, so an agent sees opponent HP as a percentage and never as exact points.
A single battle per challenge is also what the server already does.
`Best Of` is a validator rule a format opts into through its ruleset, `gen3randombattle` uses `ruleset: ['Standard']` and does not, and the `bestOfDefault` flag only sets a checkbox in the official web client.
The verification run confirms it - one room, one battle, no `Best of` rule reported.
The rule also rejects any series length that is not an odd number between three and nine, so "best of 1" is not a value we can send; it is the absence of the rule, which is our default as long as we append no `@@@ Best of = N` to the challenge.
Nothing here restricts later formats; it fixes what the MVP has to work in first.

---

## 2026-08-29 - Issues name landmarks, not implementation paths

**What:** The `to-gh-issues` skill previously said to keep specific file paths out of an issue because they go stale. That rule now applies only to implementation paths - the module someone is expected to create, the line they are expected to edit. Landmarks are named instead of withheld: the decision log, the ADR directory, the `just` recipes, and configuration files that are part of the project's contract.

**Why:** Rewriting the eight open issues for contributors with no prior context showed the old rule causing the problem it was meant to prevent. "Recorded at the repository's required decision level" is stale-proof and useless; "recorded as an ADR in `docs/adr/`" is actionable and has not moved since the repository was created. The staleness risk is real for paths that track code and near-zero for paths that are conventions. Withholding a landmark does not protect the issue, it just guarantees the reader has to come and ask, which is the cost the rewrite existed to remove.

**Result:** Issues can point at where a decision, a command, or a piece of evidence lives, while still leaving implementation layout to whoever picks the issue up. If a landmark ever does move, the fix is one search across issues, which is cheaper than every contributor asking the same question first.

---

## 2026-08-29 - Do not ship the bundler, and check the image on every pull request

Revises two entries below: the container check is no longer nightly-only, and `esbuild` is no longer an unfixable finding.

**What:** Delete `esbuild` in the build stage, before the layer the runtime stage copies.
Stop Dependabot proposing major Node bumps while still taking digest refreshes.
Run `showdown-container` wherever this workflow runs, pull requests included.

**Why:** Three things the first nightly run and PR #48 exposed.
`esbuild` is a build-time bundler Showdown declares as a runtime dependency, so `npm prune` keeps it, yet the runtime starts with `--skip-build` and nothing in `dist/` references it.
It carries a vendored Go standard library that produced 54 of the 57 alerts in the first image scan, so 95% of the Security tab came from one binary nobody executes, which is the same signal-quality problem the reporting decision was meant to avoid.
Deleting it in the build stage rather than the runtime stage is what makes it absent instead of masked, because that stage's final state is what `COPY --from=build` brings across.
Dependabot has no concept of Node's release calendar, so "stay on a supported line" has to be written as "never change the major"; PR #48 offered a move from LTS to a non-LTS release that changed no finding count.
The nightly-only choice rested on an estimate of four to eight minutes per run, and the measured job is about 90 seconds, so the reasoning behind it was simply wrong.
A pull request touching the Dockerfile is the change most likely to break the image, and it was the one class of change that reached `main` with nothing having built it.

**Result:** Fixed HIGH and CRITICAL findings against the image drop from 57 to 3, and the image from 99 MB to 95 MB.
Both figures come from this workflow's own scans of `main` and of this branch, twenty minutes apart on the same vulnerability database.
All three remaining findings arrive through `sockjs`, two of them filed upstream as `smogon/pokemon-showdown#12268`.
A broken Dockerfile now fails in review rather than the next morning.
Reintroducing a build-time dependency into the runtime tree is the thing to watch: the removal is one line, and nothing enforces it beyond the scan.

## 2026-08-28 - Let droast own Dockerfile, Compose, and ignore-file correctness

**What:** Add droast as the lint authority for `Dockerfile`, `docker-compose.yaml`, and `.dockerignore`, the way Ruff owns Python and shfmt owns shell.
`scripts/setup-droast.sh` pins one checksum-verified release binary per platform; `droast.toml` holds the policy, sets `fail-on = "warning"`, and requires every inline suppression to state a reason.
The ShellCheck bridge runs in `required` mode against the project's existing locked binary.

**Why:** droast resolves Compose services to their build contexts and checks the ignore file Docker would actually use, so one daemon-free tool covers all three artifacts.
hadolint was the mature alternative and reads Dockerfiles only, which would have meant writing and maintaining project shell to reimplement context resolution.
The accepted risk is that droast is young and single-maintainer; pinning it by checksum in a script means a release reaches us only when a human edits that file, which is the same deal the repository already makes with Lychee.
`fail-on = "warning"` is not a detail: droast exits 0 on warnings by default, so without it the hook would report and pass.

**Result:** The Dockerfile lost a masked pipeline exit status, and the apt version pin carries a written reason instead of being silently absent.
Replacing droast means replacing one script, one config file, and one hook entry.

## 2026-08-28 - Split container checks between a required lint and a nightly live run

**What:** Static linting of the container files is a required gate through `just lint`.
Building and running the image is a `container`-marked pytest module that runs nightly and on demand across amd64 and arm64, never on a pull request.
Docker's own `compose build --check` runs in that nightly job rather than as a `# check=error=true` directive in the Dockerfile.
The nightly build is deliberately uncached.

**Why:** droast depends only on the commit, so it can block a merge honestly.
A Docker build depends on Docker Hub, GitHub, and the npm registry, so it cannot.
The `container` marker exists because `external` alone would put a cold Showdown build on every pull request, including ones that only touch a README.
The Dockerfile directive was rejected because it would fail a contributor's local build the day an unrelated Docker upgrade adds a rule, which is a gate that moves without anyone changing this repository.
Caching the nightly build would hide the breakage the job exists to catch.
The health check moved from Compose into the Dockerfile so the image is correct when run directly, the port is declared once, and both droast and Trivy stop reporting a missing image-level check.

**Result:** A pull request still gets its answer in minutes.
An upstream break surfaces by the next morning as a tracked issue, because `nightly-watchdog` covers the new job.
Apple Silicon is proven by the arm64 leg rather than by argument, since Docker Desktop runs the linux/arm64 image.

## 2026-08-28 - Scan the built image, not only the repository tree

**What:** Strip npm, npx, corepack, and Yarn from the runtime stage, then scan the image the nightly job builds with Trivy, on one architecture, reporting without failing.
Results go to the Security tab as SARIF.
SBOM and provenance attestations are out of scope.

**Why:** The existing `trivy` job uses `scan-type: fs`, so it sees repository files and never the Node runtime, the Debian packages, or Showdown's npm tree, which are the bulk of what the image ships.
Removing the package managers is the same kind of decision as `cap_drop: ALL`: the runtime executes `node` and nothing else, and a package manager is a general-purpose tool for fetching more code.
It does not shrink the image, because those bytes arrive in the base image layer and deleting them here only masks them.
What it does remove is the reachable copy, and with it the `tar` finding that npm's own bundled dependencies contributed, which no change in this repository could otherwise have resolved.

Reporting rather than failing was then decided by measurement, not preference.
The remaining two fixed CRITICAL findings are both Showdown's own direct dependencies, pinned by its lockfile: `websocket-driver` through `sockjs`, and the Go standard library inside `esbuild`.
Upstream's newest lockfile still resolves the same vulnerable versions, so moving `SHOWDOWN_COMMIT` would fix neither, and a failing gate would have been red from its first night.
A check left red stops being a signal.
One architecture is enough: that package set does not differ between the two legs.
Attestations describe a pushed artifact, and this image never leaves the machine that builds it.

**Result:** The image's real dependency surface is visible in the Security tab, and reviewing those findings is part of moving the pinned revision.
Publishing the image later is the trigger to revisit attestations, not before.

## 2026-08-28 - Register composite actions with Dependabot, and check the list

**What:** The `github-actions` entry in `.github/dependabot.yml` moved from `directory: "/"` to a plural `directories:` list naming both the repository root and `/.github/actions/setup-python-env`.
`scripts/check-composite-action-coverage.sh` now asserts that every directory under `.github/` holding an `action.yml` appears in that list, wired as a local pre-commit hook and classified in `scripts/check-static.sh` so required CI runs it.

**Why:** For this ecosystem Dependabot reads `.github/workflows` and a root-level `action.yml`, and nothing else, so pins inside a local composite action are never scanned.
PR #43 showed the cost: it moved `astral-sh/setup-uv` to v10.0.1 in three workflow files and could not touch the identical pin in the composite action, leaving the required gate running two versions of the same action with nothing reporting it.
Drift like that produces no failure, only a difference, so a passing gate is not evidence against it and it has to be caught structurally.
The globstar form `'**/*'` was rejected because Dependabot then reads a workflow twice and opens duplicate pull requests (dependabot-core#10884).
Folding the two pins into one by having the `template` job reuse the composite action was also rejected: `check-template.sh` must not run against an initialized tree, and it would move the last remaining pin somewhere Dependabot cannot see at all.

**Result:** Composite action pins are maintained on the normal weekly schedule instead of by hand, and adding a composite action without registering it fails the required gate rather than drifting quietly.
The one-entry-per-composite-action cost is deliberate; it is what the coverage check makes visible.

## 2026-08-16 - Run Showdown as a pinned, disposable local service

**What:** Build Pokémon Showdown from a reviewed full commit SHA on a digest-pinned Node image, and expose the selected revision through an image label.
Limit the Docker context with a default-deny allowlist, run as the unprivileged Node user, and publish port 8000 only on host loopback.
Use tokenless local identities with ordinary abuse checks, disable privileged runtime control paths and filesystem writes, and run the single-battle MVP without child workers.

**Why:** Contributors need the same protocol and simulator behavior without maintaining manual clones or depending on public-server identity infrastructure.
The MVP values a small, observable failure boundary over public-server administration, persistence, or worker scaling.
Loopback publication is the security condition that makes tokenless development identities acceptable.

**Result:** Rebuilding restores a known server state, an unexpected failure terminates clearly for the container supervisor, and no unrelated repository content enters the image build.
Changing the upstream revision, host binding, persistence model, or worker topology requires a deliberate review of these assumptions.

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
