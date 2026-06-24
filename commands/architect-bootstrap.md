# Paired Systems Architect

**Invoke via:** `/architect-bootstrap`

**You are the coordinator.** Execute Steps 1–8 in order yourself (Step **2.5** is mandatory when intent is vague). Main agent owns the deliverable — see `commands/pipeline.md`.

Workers: **specialized scanners** in Step 5 (`readonly`) — **evidence only**. They return markdown reports; they **never** write files.

**Ideation skills** (`ce-brainstorm`, `ce-ideate`, `ce-strategy`) run in the **main agent** in Step 2.5 — interactive, user-facing. Do not dispatch them as subagents.

**You alone** merge findings, **write `architect-brief.canvas.tsx`**, and present the brief in chat.

**Pipeline:** `commands/pipeline.md`.

**Two lanes:** **WHERE** (workspace scan → canvas) + **WHAT** (ideation skills when intent is unclear). **Next:** `/create-plan` (HOW) — carries brainstorm requirements when present.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **Bootstrap Context Brief** | Brief draft (sections 1–7) |
| 1.5 | Main agent | **Intent gate + ideation lane** | User intent clear **or** requirements doc linked |
| 2 | Main agent | **Skills + Scanner triage** | Panel table published |
| 3 | Scanners (parallel) | Specialized subagents (`readonly`) | All returned — reports only |
| 4 | Main agent | Merge scan + Jira discovery | Situational Awareness table ready |
| 5 | Main agent | **Write `architect-brief.canvas.tsx`** | Canvas on disk — **not subagents** |
| 6 | Main agent | Present situational awareness in chat | User sees brief + canvas path |

---

## Step 1: Bootstrap Context Brief

**Main agent only.** Apply **probe-before-assume**: read `README`, `AGENTS.md`, root manifests — do not guess stack or boundaries.

```markdown
## Bootstrap Context Brief: {workspace-slug}

### 1. User Intent
### 2. Starting Hypothesis
### 3. Scan Questions (numbered — scanners must answer each)
### 4. Prior Art
### 5. Jira Discovery keywords (if applicable)
### 6. Workspace Type Signals
- Primary kind: code repo | docs/coordination | platform/GitOps | monorepo | multi-root
- Build surfaces detected: (package.json, go.mod, pyproject.toml, Makefile, Dockerfile, Tekton, etc.)
- Agent-facing docs: README quality, AGENTS.md, .cursor/rules presence

### 7. Initial Cynefin Read
- Domain for the stated intent: Clear | Complicated | Complex | Chaotic | Disorder
- If Disorder: list clarifying questions before heavy scanning

### 8. Requirements Anchor (if any)
- Path to `docs/brainstorms/*-requirements.{md,html}` or `docs/ideation/*` artifact
- One-paragraph scope summary for scanners (from brainstorm or user)
- Link to `STRATEGY.md` at repo root if it exists
```

**Gate:** Sections 1–3 and 6 complete before Step 1.5.

---

## Step 1.5: Intent Gate & Ideation Lane

**Main agent only.** Bootstrap answers **WHERE** (workspace reality). Compound-engineering ideation skills answer **WHAT** (scope, behavior, success criteria) when intent is not yet plan-ready.

Read **`ce-brainstorm/SKILL.md`** Phase 0.2 (clarity assessment) before routing, if available.

### Route (pick one)

| Signal | Route | Action |
| :--- | :--- | :--- |
| **Clear intent** — acceptance criteria, bounded scope, or explicit "scan only" | **Skip ideation** | Finalize brief §1–2; proceed to Step 2 |
| **Vague intent** — "improve X", "explore", Disorder, missing §1 | **`ce-brainstorm`** | Read plugin skill; run interactive Q&A (one question per turn). Write or update `docs/brainstorms/{slug}-requirements.md` when durable handoff needed |
| **No chosen direction** — "what should we build", "give me ideas" | **`ce-ideate` → `ce-brainstorm`** | Ideate produces ranked options in `docs/ideation/`; user picks one; brainstorm defines it |
| **`STRATEGY.md` missing** on product/code repo with greenfield intent | **Flag only** | Note in brief + canvas; suggest `/ce-strategy` — do **not** block workspace scan |
| **Existing brainstorm/ideation doc** in repo | **Resume** | Read artifact; confirm with user; fold into brief §8 |

### Ideation rules

1. **Interactive skills stay in main agent** — do not Task-dispatch `ce-brainstorm` or `ce-ideate`.
2. **Workspace-only bootstrap** — user says "bootstrap this repo" with no feature → skip brainstorm; scan only.
3. **Lightweight when clear** — per `ce-brainstorm` Phase 0.2: if requirements already clear, confirm in 2–3 lines and skip long Q&A.
4. **After ideation** — update brief §1 User Intent, §2 Hypothesis, §8 Requirements Anchor; scanners validate against §8 in Step 3.

**Gate:** §1 is actionable **or** §8 links a requirements doc before Step 2.

---

## Step 2: Skills + Scanner Triage

**Main agent only.** Read applicable skills **before** dispatching scanners. Publish the scanner panel in chat.

### Skills (read and inject into prompts)

| Skill / plugin | Path | When to read | Inject into |
| :--- | :--- | :--- | :--- |
| **Probe before assume** | `skills/probe-before-assume/SKILL.md` | **Always** | Brief discipline + every scanner Task prompt |
| **Cynefin sense-making** | `skills/cynefin-sense-making/SKILL.md` | **Always** | Brief §7 + Step 1.5 routing |
| **Brainstorm (WHAT)** | Plugin `ce-brainstorm/SKILL.md` | Step 1.5 vague intent / Disorder | Main agent Q&A; `docs/brainstorms/` artifact → brief §8 |
| **Ideate** | Plugin `ce-ideate/SKILL.md` | Step 1.5 no chosen direction | Before brainstorm; `docs/ideation/` → user picks → brainstorm |
| **Strategy grounding** | Plugin `ce-strategy/SKILL.md` | `STRATEGY.md` exists or greenfield product | Read into brief §8; canvas Intent row |
| **Canvas** | `skills-cursor/canvas/SKILL.md` | **Always** (before Step 6) | Canvas authoring rules |
| **Platform design review** | `skills/platform-design-review/SKILL.md` | Platform/API/IaC/SDK/GitOps surface detected | Scanner **C** + canvas Platform Economics section |
| **Jira (Atlassian plugin)** | _(optional — add your own Jira skill)_ | Jira keywords in §5 or tracked-workspace | Step 5 Jira discovery procedure |
| **Agent compatibility** | Plugin `check-agent-compatibility/SKILL.md` | Code repo with README + at least one build surface | Compatibility lane **D–G** + score synthesis in Step 5 |
| **Slack research** | Plugin `ce-slack-research/SKILL.md` | User asks for org/team context | Optional subagent **J** |
Read each skill file; paste the **relevant checklist section** into matching scanner prompts (not the entire skill).

### Core scanners (always dispatch)

| ID | `subagent_type` | Model | Lens |
| :--- | :--- | :--- | :--- |
| **A** | `ce-repo-research-analyst` | `claude-4.6-opus-max-thinking` | Structure, conventions, docs, call chains, boundaries (`very thorough`) |
| **B** | `explore` | `gemini-3.1-pro` | Stack, CI/CD, dependencies, entrypoints (`medium` or `very thorough`) |
| **C** | `ce-architecture-strategist` | `claude-4.6-opus-max-thinking` | Hexagonal boundaries, coupling, platform economics signals, long-term risks |

### Conditional scanners (dispatch when signal matches)

| ID | `subagent_type` | Model | Trigger |
| :--- | :--- | :--- | :--- |
| **D** | `compatibility-scan-review` | `composer-2.5-fast` | Code repo — deterministic agent-compat CLI score |
| **E** | `startup-review` | `composer-2.5-fast` | Same as D — cold-start path |
| **F** | `validation-review` | `composer-2.5-fast` | Same as D — cost of verifying a small change |
| **G** | `docs-reliability-review` | `composer-2.5-fast` | Same as D — docs vs reality |
| **H** | `ce-git-history-analyzer` | `gemini-3.1-pro` | `.git` present + code repo (not docs-only) |
| **I** | `ce-learnings-researcher` | `gpt-5.4-medium` | `docs/solutions/` exists OR institutional-knowledge request |
| **J** | `ce-web-researcher` | `gemini-3.1-pro` | External prior art, standards, or market context requested |
| **K** | `ce-slack-researcher` | `gpt-5.4-medium` | User requests Slack/org context (read `ce-slack-research/SKILL.md` first) |

**Agent Compatibility lane:** When **D** triggers, dispatch **D + E + F + G** together (four separate Tasks — do not collapse). After all return, synthesize **Agent Compatibility Score** per `check-agent-compatibility` skill (deterministic × 0.7 + workflow average × 0.3). Add score + top fixes to canvas and chat.

**Panel limits:** Always dispatch **A + B + C**. Cap **10 parallel** Tasks per message. If over cap: **A → B → C** (never drop) → **D–G bundle** → **H** → **I**. Use a second message only if the cap blocks the compatibility bundle.

**Model policy:** Core scanners (A–C, H–I) use **thinking-tier** only. Compatibility lane (D–G) may use fast models per plugin agent definitions.

---

## Step 3: Parallel Workspace Scan (WHERE)

**WAIT** for all scanners. **Subagents do NOT write Canvas or any files.**

Each Task prompt MUST include:

1. Full **Bootstrap Context Brief** (all sections from Step 1)
2. **Skill addendum** — pasted checklist from Step 2 (probe, platform, etc. as applicable)
3. **Mission:** return markdown scan report only — **do not write files, do not create canvas**
4. **Output contract:** tech stack, boundaries, files validated, gaps/risks, answers to Scan Questions; **validate brief §8 requirements against codebase** when present; compatibility agents use their plain-text score format

`readonly: true` on every scanner.

Per-scanner fallback (reasoning tier only for A/C/H/I):

- A: `claude-4.6-opus-max-thinking` → `claude-4.6-sonnet-medium-thinking`
- B: `gemini-3.1-pro` → `gpt-5.4-medium` → `composer-2.5`
- C: `claude-4.6-opus-max-thinking` → `claude-4.6-sonnet-medium-thinking`

---

## Step 4: Merge + Jira Discovery (WHERE + WHAT)

**Main agent only.**

1. Merge scanner reports (union; flag contradictions).
2. **Jira discovery** — if §5 applies and a Jira MCP/skill is configured: search overlapping epics/tasks (MCP read), present findings, ask user about epic placement (do not create without consent).
3. **Agent Compatibility synthesis** — if D–G ran, compute combined score and merge Top fixes into gaps table.
4. **Institutional learnings** — if **I** ran, surface applicable `docs/solutions/` hits in Prior Art for `/create-plan`.
5. Build **Situational Awareness** data for Canvas (tables, stats, gaps).


---

## Step 5: Write Canvas (main agent only)

**Only the main agent** uses the Write tool for the canvas file. Scanners never reach this step.

1. Read `~/.cursor/skills-cursor/canvas/SKILL.md` before authoring.
2. Follow `references/architect-brief-canvas.md` (structure, `cursor/canvas` imports, `useHostTheme()`).
3. Write to:

   `~/.cursor/projects/<workspace>/canvases/architect-brief.canvas.tsx`

   Resolve `<workspace>` from open workspace paths (list `~/.cursor/projects/` if needed).

4. Canvas sections:
   - Header stats (include **Agent Compatibility Score** `Stat` when D–G ran)
   - **Intent & scope** — user intent, link to requirements doc (`docs/brainstorms/`), `STRATEGY.md` one-liner if present
   - Situational Awareness table
   - Key boundaries (Ports & Adapters)
   - Gaps / risks (union; compatibility Top fixes merged here)
   - **Platform Economics** table (when platform-design-review skill applied — Innovation, Cimarron, Railway/Guardrail verdicts)
   - Jira discovery summary (if applicable)
   - Pipeline footer (`bootstrap → create-plan → pre-flight → …`; note if brainstorm doc is input to create-plan)

**Gate:** File exists on disk before Step 6. Chat-only output is not sufficient.

---

## Step 6: Present in Chat

Summarize: **intent & scope** (or requirements doc path), tech stack, boundaries, top risks, Jira findings, agent compatibility (if run), **Initial Cynefin read**, **absolute path to canvas**. Full brief in conversation — not only in the file.

**Standing orders** (remainder of session): per `references/architect-brief-canvas.md`.

End with one of:
- *"Bootstrap complete. Requirements at `{path}`. Run `/create-plan` when ready."* (when §8 doc exists)
- *"Bootstrap complete (workspace scan only). Run `/create-plan` or `/ce-brainstorm` first if scope is still open."*

---

## Anti-Patterns

- Letting scanners or any subagent write `.canvas.tsx`
- 3× generic `explore` with identical lens (use specialized panel)
- Scanners without full Bootstrap Context Brief + skill addendum
- Collapsing D–G compatibility checks into one prompt
- Chat-only deliverable with no canvas file
- Guessing workspace type without reading manifests/README
- Dispatching `ce-brainstorm` / `ce-ideate` as subagents (main-agent interactive only)
- Heavy scanning while User Intent is still Disorder with no §8 anchor
- Skipping Step 1.5 when user presents a vague feature request

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | **main agent** (Canvas author) + specialized readonly scanners |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors, iterative) |
| 4 | `/execute-plan` | main agent (+ `execute-plan` executor) |
| 5 | `/codereview` | main agent (+ specialized review panel) |
