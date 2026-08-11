---
name: to-gh-issues
description: Break a plan, spec, or the current conversation into a set of issues, each declaring its blocking edges, published to GitHub - edges as text in one file per issue locally, or native blocking links on GitHub.
disable-model-invocation: true
---

# To Issues

Break a plan, spec, or conversation into a set of **issues** - thin vertical slices, each declaring the issues that **block** it.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, a plan, a todo, an issue number, or URL) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Issue titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **indivisible and irreducible** thin vertical issue slices.

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) - vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Any prefactoring should be done first

Give each issue its **blocking edges** - the other issues that must complete before it can start. An issue with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change - rename a column, retype a shared symbol - whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into an indivisible and irreducible issue; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own issue blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a issue blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify issue - green is promised only there.

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each issue, show:

- **Title**: short descriptive name
- **Labels**: the associated GitHub labels
- **Blocked by**: which other issues (if any) must complete first
- **What it delivers**: the end-to-end behaviour this issue makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct - does each issue only depend on issues that genuinely gate it?
- Should any issues be merged or split further?
- Is the issue labelled correctly?

Iterate until the user approves the breakdown.

### 5. Generate Diagram

If, and only if, a `excalidraw skill` or `mermaid skill` for diagram generation is available to you, optionally, create a diagram that supports explanation of the issue or supports a direction for a solution. An example could be when an issue is related to the architecture where a visual can support

### 6. Publish the issues to GitHub

Publish the approved issues.

- **Local files** → write one file per issue under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-issue file template below - one issue per file, never a single combined file.
- **GitHub** → publish one issue in dependency order (blockers first) so each issue's blocking edges can reference real identifiers. Use the platform's native blocking / sub-issue relationship where it has one; otherwise set each issue's "Blocked by" to the blocking issues. Apply relevant labels to the issue.

Work the **frontier**: any issue whose blockers are all done. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue.

```markdown
# <NN> - <Issue title>

**What to build:** the end-to-end behaviour this issue makes work, from the user's perspective - not a layer-by-layer implementation list.

**Blocked by:** the numbers/titles of the issues that gate this one, or "None - can start immediately".

**Status:** ready

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

Use the existing GitHub Issue Templates where applicable else default to creating a blank issue with the following as a template:

```markdown
## Parent

A reference to the parent issue on GitHub (if the source was an existing issue, otherwise omit this section).

## What & Why

Why it exists, and what problem it solves for the user. The end-to-end behaviour this issue makes work, from the user's perspective - not layer-by-layer implementation.

## Rough code/textual sketch of an approach (optional)

A rough starting point defined using pseudo code - where it'd live, the shape of it, a gotcha to watch. Leave blank if unsure.

## Mockup, diagram, or screenshot (optional)

Drag files straight into this box. A rough sketch of the interface, a flow diagram, an architecture diagram, or a shot of how another tool solves it says more than a paragraph. Leave blank if unsure.

- ![Alt text](image_url)

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A reference to each blocking issue, or "None - can start immediately".
```

In either form, avoid specific file paths or code snippets - they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts - not a working demo, just the important bits.
