---
name: to-gh-issues
description: Break a plan, specification, or the current conversation into dependency-aware issues and publish them as one local file per issue or as GitHub issues with native blocking links when available.
---

# To Issues

Break a plan, specification, or conversation into thin vertical issue slices.
Make each issue declare the issues that block it.

## Process

### 1. Gather context

Work from the context already available in the conversation.
If the user supplies a specification path, plan, todo, issue number, URL, or other reference, fetch it and read its full body and comments.

### 2. Explore the codebase when useful

If the codebase has not already been explored, inspect it enough to understand its current state.
Use the project's domain glossary in issue titles and descriptions, and respect relevant architecture decision records.

Look for opportunities to prefactor the code to make implementation easier.
Make the change easy, then make the easy change.

### 3. Draft vertical slices

Break the work into indivisible and irreducible thin vertical issue slices.

Apply these vertical-slice rules:

- Make each slice a narrow but complete path through every affected layer, such as schema, API, UI, and tests.
- Do not create horizontal slices that cover only one layer.
- Ensure each completed slice is demoable or independently verifiable.
- Sequence necessary prefactoring before the behavior it enables.

Give each issue its blocking edges: the other issues that must complete before it can start.
An issue with no blockers can start immediately.

Treat wide refactors as the exception to vertical slicing.
A wide refactor is one mechanical change, such as renaming a column or retyping a shared symbol, whose blast radius fans across the codebase so one edit breaks too many call sites for any vertical slice to land green.
Do not force it into one indivisible issue.
Sequence it as expand-contract:

1. Expand by adding the new form beside the old form without breaking callers.
2. Migrate callers in batches sized by blast radius, with each batch in its own issue blocked by the expansion issue.
3. Contract by deleting the old form in an issue blocked by every migration batch.

Keep CI green after every batch.
If even the migration batches cannot stay green alone, retain the sequence on an integration branch and make every batch block a final integrate-and-verify issue where green is restored.

### 4. Quiz the user

Present the proposed breakdown as a numbered list.
For each issue, show:

- **Title**: A short, descriptive name.
- **Labels**: The applicable GitHub labels.
- **Blocked by**: The other proposed issues that genuinely gate it, or none.
- **What it delivers**: The end-to-end behavior this issue makes work.

Ask the user:

- Does the granularity feel right, or is it too coarse or too fine?
- Are the blocking edges correct?
- Should any issues be merged or split further?
- Is each issue labeled correctly?
- Should the approved issues be written locally or published to GitHub?

Iterate until the user approves the breakdown and publication destination.

### 5. Generate a diagram only when supported and useful

If, and only if, an Excalidraw or Mermaid diagram-generation skill is available, optionally create a diagram when it materially clarifies architecture, dependencies, or solution direction.

### 6. Publish the issues

Publish only the approved issues to the approved destination.

- **Local files**: Write one file per issue under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order with blockers first.
  Use the local issue template below.
  List each blocking issue by its local number and title.
  Never combine multiple issues into one file.
- **GitHub**: Publish issues in dependency order with blockers first so every blocking edge can reference a real issue identifier.
  Use native blocking or sub-issue relationships when GitHub and the available tooling support them.
  Otherwise, list the blocking issues in the `Blocked by` section.
  Apply relevant existing labels.

Work the frontier: any issue whose blockers are all complete.
For a purely linear chain, this means working from top to bottom.

Do not close a source or parent issue, and do not edit its title, body, labels, or status.

```markdown
# <NN> - <Issue title>

**What to build:** Describe the end-to-end behavior this issue makes work from the user's perspective, not a layer-by-layer implementation list.

**Blocked by:** List the numbers and titles of the issues that gate this one, or "None - can start immediately."

**Status:** ready

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

Use an existing GitHub issue template when one applies.
Otherwise, use this template:

```markdown
## Parent

Reference the source issue when the source was an existing GitHub issue.
Otherwise, omit this section.

## What & Why

Explain why the issue exists and what problem it solves for the user.
Describe the end-to-end behavior this issue makes work, not a layer-by-layer implementation list.

## Rough code/textual sketch of an approach (optional)

Give a rough starting point in pseudocode, including where the work belongs, its shape, and an important gotcha.
Leave this section blank when unsure.

## Mockup, diagram, or screenshot (optional)

Include a rough interface sketch, flow diagram, architecture diagram, or screenshot when it communicates the decision better than prose.
Leave this section blank when unsure.

![Alt text](image_url)

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- Reference each blocking issue, or write "None - can start immediately."
```

In either form, avoid specific file paths and code snippets because they become stale quickly.
Exception: if a prototype produced a snippet that captures a decision more precisely than prose, inline only the decision-rich portion and state briefly that it came from a prototype.
