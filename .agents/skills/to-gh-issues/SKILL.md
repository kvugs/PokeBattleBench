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

#### Vertical slice rules

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) - vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Any prefactoring should be done first

Give each issue its **blocking edges** - the other issues that must complete before it can start. An issue with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change - rename a column, retype a shared symbol - whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into an indivisible and irreducible issue; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own issue blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a issue blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify issue - green is promised only there.

### 4. Write each issue for a stranger

Every issue is read by someone who was not in the conversation that produced it. Write for a contributor who has never spoken to you, has not read the plan, and does not know the project's shorthand. If they have to ask a question before they can start, the issue is not finished.

Three habits carry most of the weight.

**Define the domain before you use it.** Name what each external system is, what it does, and what it owns, in plain words. Show one concrete example - a real payload, a real message, a real command - because one example replaces a paragraph of description. If the issue turns on a term of art, define the term in the issue instead of sending the reader away to find out.

**Give every criterion an actor and a destination.** "The decision is recorded at the required level" tells a stranger nothing. "The maintainers record the decision as an ADR in `docs/adr/`" tells them who acts, what they produce, and where it lands. Passive criteria are where hidden context collects, so read each one back and ask: who does this, and where does the result go?

**Flag a decision gate at the top.** If part of the issue needs a call only the maintainers can make, say so in the first section, list the exact questions to answer, and say where the answer gets recorded. An issue that looks like implementation and turns out to need a decision is how work gets claimed and then stalls.

#### Tells that context leaked out of the issue

Scan the draft for these. Each is a phrase that resolves only for people who were in the room:

- **A definite article in front of an undefined thing** - "the approved scenario", "the agreed format", "the chosen approach". Name the thing, or name the issue that decides it.
- **A project-internal level or path** - "at the required decision level", "in the external path", "the usual gate". Name the file, the label, or the command instead.
- **An unexplained proper noun** - a library, a protocol, a service, or an ADR number used without one line saying what it is.
- **A criterion nobody can fail** - "the design is appropriate", "the boundaries are clean". If two reviewers could disagree about whether it passed, it is a preference, not a criterion.
- **An inherited assumption** - a default carried over from an earlier draft that nobody actually agreed to. Call it a candidate, and name the issue that settles it.

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each issue, show:

- **Title**: short descriptive name
- **Labels**: the associated GitHub labels
- **Blocked by**: which other issues (if any) must complete first
- **What it delivers**: the end-to-end behaviour this issue makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct - does each issue only depend on issues that genuinely gate it?
- Should any issues be merged or split further?
- Is the issue labelled correctly? Use only labels that already exist in the repository; propose a new one separately rather than inventing it here.
- Could a contributor who has never spoken to you start this issue without asking a question first?
- Does any issue quietly need a decision only the maintainers can make?

Iterate until the user approves the breakdown.

### 6. Generate Diagram (optional)

If, and only if, a `excalidraw skill` or `mermaid skill` for diagram generation is available to you, optionally, create a diagram that supports explanation of the issue or supports a direction for a solution. An example could be when an issue is related to the architecture where a visual can support understanding and framing of the issue and scope.

### 7. Publish the issues to GitHub

Publish the approved issues.

- **Local files** → write one file per issue under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-issue file template below - one issue per file, never a single combined file.
- **GitHub** → publish one issue in dependency order (blockers first) so each issue's blocking edges can reference real identifiers. Use the platform's native blocking / sub-issue relationship where it has one; otherwise set each issue's "Blocked by" to the blocking issues. Apply relevant labels to the issue.

Work the **frontier**: any issue whose blockers are all done. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue.

#### Issue template

Use the existing GitHub Issue Templates where applicable else default to creating a blank issue with the following as a template:

```markdown

## Parent

A reference to the parent issue on GitHub (if the source was an existing issue, otherwise omit this section).

## Decision required before implementation (omit when there is none)

The call that has to be made partway through, who makes it, the exact questions to answer, and where the answer is recorded. Delete this section for an issue that is implementation only.

## Context

What a reader who has never seen this project needs in order to start. What the external systems are and what they own, terms of art defined in plain words, and one concrete example - a real payload, message, or command. Say what is already decided and what is deliberately still open, so nobody inherits an assumption by accident.

## What & Why

Why it exists, and what problem it solves for the user. The end-to-end behaviour this issue makes work, from the user's perspective - not layer-by-layer implementation.

## Rough code/textual sketch of an approach (optional)

A rough starting point defined using pseudo code - where it'd live, the shape of it, a gotcha to watch. Leave blank if unsure.

## Mockup or diagram (optional)

Insert files straight into this box. A rough sketch of the interface, a flow diagram, an architecture diagram, or a shot of how another tool solves it says more than a paragraph. Leave blank if unsure.

- ![Alt text](image_url)

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

Each criterion names who acts and what the result is, and can be judged pass or fail by someone who was not in the room.

## How to verify by hand

The commands a contributor runs to watch this work, in order, ready to paste.

## Out of scope

The neighbouring work this issue deliberately does not do, each line pointing at the sibling issue that owns it.

## Blocked by

- A reference to each blocking issue, or "None - can start immediately".

```

In either form, separate **landmarks** from **implementation paths**. Landmarks are the durable, conventional places a contributor has to know about to act at all: the decision log, the ADR directory, a task-runner recipe, a configuration file that is part of the project's contract. Name those - withholding them is exactly what forces a stranger to come and ask. Implementation paths are the module you expect someone to create or the line you expect them to edit; leave those out, because they go stale and they pre-empt a call that belongs to whoever picks the issue up.

Code snippets follow the same rule. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts - not a working demo, just the important bits.
