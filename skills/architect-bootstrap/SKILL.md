---
name: architect-bootstrap
description: >-
  Stage 1 of the Antigravity agent pipeline. Scans workspace boundaries, root manifests,
  and architecture to build an architect brief and visual canvas with situational awareness.
  Use when starting a new project, exploring an unfamiliar workspace, or defining the
  'where and what' before planning.
---

# Paired Systems Architect

**Invoke via:** `/architect-bootstrap`

**You are the coordinator.** Execute Steps 1–8 in order yourself (Step **2.5** is mandatory when intent is vague). Main agent owns the deliverable — see [Agent Pipeline Contract](../agent-pipeline/SKILL.md).

Workers: **specialized scanners** in Step 5 (`readonly`) — **evidence only**. They return markdown reports; they **never** write files.

**Ideation skills** run in the **main agent** in Step 2.5 — interactive, user-facing. Do not dispatch them as background subagents.

**You alone** merge findings, **write `architect-brief.canvas.tsx`**, present the brief in chat, and call `memory_store`.

**Pipeline:** [Agent Pipeline Contract](../agent-pipeline/SKILL.md) (memory bookends).

**Two lanes:** **WHERE** (workspace scan → canvas) + **WHAT** (ideation skills when intent is unclear). **Next:** `/create-plan` (HOW) — carries brainstorm requirements when present.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | **Bootstrap Context Brief** | Brief draft (sections 1–8) |
| 2.5 | Main agent | **Intent gate + ideation lane** | User intent clear **or** requirements doc linked |
| 3 | Main agent | **Skills + Scanner triage** | Panel table published |
| 4 | Scanners (parallel) | Specialized subagents (`readonly`) | All returned — reports only |
| 5 | Main agent | Merge scan + Jira discovery | Situational Awareness table ready |
| 6 | Main agent | **Write `architect-brief.canvas.tsx`** | Canvas on disk — **not subagents** |
| 7 | Main agent | Present situational awareness in chat | User sees brief + canvas path |
| 8 | Main agent | **`memory_store` NOW** | Indexed |

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work**:

```
query: workspace bootstrap, architecture, canvas brief, {repo or workspace name}
limit: 5
```

Present hits with similarity > 0.6. Carry into Step 2 Prior Art.

---

## Step 2: Bootstrap Context Brief

**Main agent only.** Apply **probe-before-assume**: read `README`, `AGENTS.md`, root manifests — do not guess stack or boundaries.

```markdown
## Bootstrap Context Brief: {workspace-slug}

### 1. User Intent
### 2. Starting Hypothesis
### 3. Scan Questions (numbered — scanners must answer each)
### 4. Prior Art (memory hits from Step 1)
### 5. Jira Discovery keywords (if applicable)
### 6. Workspace Type Signals
- Primary kind: code repo | docs/coordination | platform/GitOps | monorepo | multi-root
- Build surfaces detected: (package.json, go.mod, pyproject.toml, Makefile, Dockerfile, Tekton, etc.)
- Agent-facing docs: README quality, AGENTS.md, rules presence

### 7. Initial Cynefin Read
- Domain for the stated intent: Clear | Complicated | Complex | Chaotic | Disorder
- If Disorder: list clarifying questions before heavy scanning

### 8. Requirements Anchor (if any)
- Path to `docs/brainstorms/*-requirements.{md,html}` or `docs/ideation/*` artifact
- One-paragraph scope summary for scanners (from brainstorm or user)
- Link to `STRATEGY.md` at repo root if it exists
```

**Gate:** Sections 1–3 and 6 complete before Step 2.5.

---

## Step 2.5: Intent Gate & Ideation Lane

**Main agent only.** Bootstrap answers **WHERE** (workspace reality). Ideation skills answer **WHAT** (scope, behavior, success criteria) when intent is not yet plan-ready.

### Route (pick one)

| Signal | Route | Action |
| :--- | :--- | :--- |
| **Clear intent** — acceptance criteria, bounded scope, or explicit "scan only" | **Skip ideation** | Finalize brief §1–2; proceed to Step 3 |
| **Vague intent** — "improve X", "explore", Disorder, missing §1 | **`brainstorm`** | Run interactive Q&A (one question per turn). Write or update `docs/brainstorms/{slug}-requirements.md` when durable handoff needed |
| **No chosen direction** — "what should we build", "give me ideas" | **`ideate` → `brainstorm`** | Produce ranked options in `docs/ideation/`; user picks one; brainstorm defines it |
| **`STRATEGY.md` missing** on product/code repo with greenfield intent | **Flag only** | Note in brief + canvas; suggest strategy session — do **not** block workspace scan |
| **Existing brainstorm/ideation doc** in repo | **Resume** | Read artifact; confirm with user; fold into brief §8 |

### Ideation rules

1. **Interactive skills stay in main agent** — do not Task-dispatch interactive ideation subagents.
2. **Workspace-only bootstrap** — user says "bootstrap this repo" with no feature → skip brainstorm; scan only.
3. **Lightweight when clear** — if requirements already clear, confirm in 2–3 lines and skip long Q&A.
4. **After ideation** — update brief §1 User Intent, §2 Hypothesis, §8 Requirements Anchor; scanners validate against §8 in Step 4.

**Gate:** §1 is actionable **or** §8 links a requirements doc before Step 3.

---

## Step 3: Skills + Scanner Triage

**Main agent only.** Read applicable skills **before** dispatching scanners. Publish the scanner panel in chat.

### Skills (read and inject into prompts)

| Skill / plugin | Path | When to read | Inject into |
| :--- | :--- | :--- | :--- |
| **Probe before assume** | `skills/probe-before-assume/SKILL.md` | **Always** | Brief discipline + every scanner Task prompt |
| **Cynefin sense-making** | `skills/cynefin-sense-making/SKILL.md` | **Always** | Brief §7 + Step 2.5 routing |
| **Platform design review** | `skills/platform-design-review/SKILL.md` | Platform/API/IaC/SDK/GitOps surface detected | Scanner **C** + canvas Platform Economics section |

### Core scanners (always dispatch)

| ID | Role | Model | Lens |
| :--- | :--- | :--- | :--- |
| **A** | Codebase Structure Analyst | `inherit` / `pro` | Structure, conventions, docs, call chains, boundaries |
| **B** | Stack & Pipeline Explorer | `flash` | Stack, CI/CD, dependencies, entrypoints |
| **C** | Architecture Strategist | `inherit` / `pro` | Hexagonal boundaries, coupling, platform economics signals, long-term risks |

---

## Step 4: Parallel Workspace Scan (WHERE)

**WAIT** for all scanners. **Subagents do NOT write Canvas or any files.**

Each Task prompt MUST include:

1. Full **Bootstrap Context Brief** (all sections from Step 2)
2. **Skill addendum** — pasted checklist from Step 3 (probe, platform, etc. as applicable)
3. **Mission:** return markdown scan report only — **do not write files, do not create canvas**
4. **Output contract:** tech stack, boundaries, files validated, gaps/risks, answers to Scan Questions; **validate brief §8 requirements against codebase** when present.

`readonly: true` on every scanner.

---

## Step 5: Merge + Discovery (WHERE + WHAT)

**Main agent only.**

1. Merge scanner reports (union; flag contradictions).
2. Surface applicable historical hits in Prior Art for `/create-plan`.
3. Build **Situational Awareness** data for Canvas (tables, stats, gaps).

---

## Step 6: Write Canvas (main agent only)

**Only the main agent** writes the canvas file. Scanners never reach this step.

1. Follow `references/architect-brief-canvas.md` structure.
2. Write to:
   `canvases/architect-brief.canvas.tsx` (or `.agents/canvases/architect-brief.canvas.tsx`).
3. Canvas sections:
   - Header stats
   - **Intent & scope** — user intent, link to requirements doc (`docs/brainstorms/`)
   - Situational Awareness table
   - Key boundaries (Ports & Adapters)
   - Gaps / risks
   - **Platform Economics** table (when platform-design-review skill applied)
   - Pipeline footer (`bootstrap → create-plan → pre-flight → …`)

**Gate:** File exists on disk before Step 7. Chat-only output is not sufficient.

---

## Step 7: Present in Chat

Summarize: **intent & scope** (or requirements doc path), tech stack, boundaries, top risks, **Initial Cynefin read**, **absolute path to canvas**. Full brief in conversation — not only in the file.

---

## Step 8: Index (mandatory)

Call `memory_store` **after** canvas write:

- `title`: `architect-brief-{workspace-slug}` or canvas filename
- `content`: chat summary **plus** key canvas data (scores, top gaps)
- `doc_type`: `canvas_brief`
- `workspace`: current workspace path

End with one of:
- *"Bootstrap complete. Requirements at `{path}`. Run `/create-plan` when ready."*
- *"Bootstrap complete (workspace scan only). Run `/create-plan` when ready."*
