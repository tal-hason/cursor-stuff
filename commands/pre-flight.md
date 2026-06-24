# Pre-Flight Review

**Invoke via:** `/pre-flight`

**You are the coordinator.** Execute Steps 1–5 in order yourself. Main agent owns the deliverable — see `commands/pipeline.md`.

Spawn **3 `pre-flight` auditors** in Step 2 (`readonly: true`). You merge their output and author the unified report in **this** conversation.

**Requires:** A `.plan.md` from `/create-plan` (path or @-mention).

**Iterative:** Run this command **as many times as needed** — each run writes a new timestamped report. Re-runs are encouraged, not penalized. See `commands/pipeline.md`.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | Build **Pre-Flight Context Package** | Full plan loaded — not an excerpt |
| 2 | 3 auditors (parallel) | Dispatch `pre-flight` subagents | All auditors returned |
| 3 | Main agent | Pessimistic merge + correlation | Report draft ready |
| 4 | Main agent | Write `*-Pre-Flight-Review_*.md` | File on disk |
| 5 | Main agent | Present dashboard | User sees confidence + path to green |

**Soft gate for `/execute-plan`:** ≥ 90% and not Stop → ready; otherwise Path to Green or user override (see `pipeline.md`).

**Next:** `/execute-plan` → `/codereview` (or edit plan + run `/pre-flight` again)

---

## Step 1: Pre-Flight Context Package

**Main agent only.** Read the plan file from disk. Build this package — auditors receive the **entire package**, not a summary.

```markdown
## Pre-Flight Context Package: {plan-slug}

### 1. Plan Identity
- **Path:** absolute path to `.plan.md`
- **Name / overview:** from YAML frontmatter
- **Workspace:** current workspace root

### 2. Full Plan Text
(paste complete plan body + YAML frontmatter — every section, every todo)

### 3. Plan Structure Index
- Numbered atomic steps with Cynefin tags from the plan
- Complex / probe-required steps highlighted
- Files referenced in the plan (absolute paths)

### 4. Prior Art & Iteration History
- **All prior** `*-Pre-Flight-Review_*.md` for this plan slug (summarize confidence trend)
- If plan changed since last pre-flight: note what changed (diff summary or user statement)

### 5. Audit Mission
Stress-test the plan above. Classify each step (Cynefin), score confidence, find gaps. Do not execute code.
```

**Gate:** Package sections 1–3 complete before Step 2. Never dispatch auditors with only the user's last message or a plan excerpt.

---

## Step 2: Parallel Audits

**WAIT** for all auditors before Step 3.

Dispatch **3** `pre-flight` subagents in **one message**. `readonly: true`.

| Auditor | Model | Thinking | Lens |
| :--- | :--- | :--- | :--- |
| **A** | `claude-4.6-opus-max-thinking` | Max | Cynefin + architecture depth, integration patterns |
| **B** | `gemini-3.1-pro` | High | Gap analysis, missing context, plan completeness |
| **C** | `Codex 5.3` | High | Contracts, platform abstractions, edge cases |

**Optional security lane (4th auditor):** When the plan touches auth/authz, secrets, public endpoints, PII, or trust boundaries — dispatch **`ce-security-lens-reviewer`** in the **same message** (`readonly: true`, `claude-4.6-opus-max-thinking`). Mission: plan-level threat model gaps (not code audit). Findings merge into Gap Analysis and Path to Green.

**Model policy:** Thinking-tier models only. No `composer-2.5-fast` or `gpt-5.3-codex-high-fast`.

### Each Task prompt MUST include

1. **Full Pre-Flight Context Package** (all 5 sections from Step 1)
2. **Mission:** execute the `pre-flight` agent procedure; return structured Pre-Flight Dashboard only
3. **Output contract:** per `agents/pre-flight.md` output format

Per-auditor fallback: A → sonnet-high; B → gpt-5.4-medium → composer-2.5; C → sonnet-medium → gemini-3.1-pro.

---

## Step 3: Merge (Pessimistic)

| Rule | Policy |
| :--- | :--- |
| Confidence per task | **Minimum** across auditors |
| Overall confidence | **Minimum** across auditors |
| Cynefin | **More complex** wins |
| Gaps / blockers | **Union** — one auditor flag = real gap |
| Contradictions | Flag for user; do not silently resolve |
| Path to Green | Merge, dedupe, blockers first |

**Cross-issue correlation:** Collapse findings that share one root cause before finalizing.

Produce **Auditor agreement matrix** (task × A/B/C × confidence).

---

## Step 4: Write Report

Path: `~/.cursor/plans/{plan-slug}-Pre-Flight-Review_YYYY-MM-DD_HHMM.md`

Required sections:

1. Confidence Dashboard (overall %, Ready/Caution/Stop, auditors, top blockers)
2. Task-by-Task Analysis (min confidence, agreement column)
3. Integration Risk Matrix
4. Platform Abstraction Audit (if applicable)
5. Gap Analysis (< 95% tasks — ambiguity, missing context, risk, source auditor)
6. **Security Threat Model** (if security lane ran — auth assumptions, data exposure, missing controls)
7. Auditor Disagreements (if any)
8. Path to Green (blockers + suggestions)

---

## Step 5: Present

1. **Paste the full Pre-Flight Dashboard in this conversation.**
2. State outcome (no pushback on re-runs):
   - *"Confidence {N}%. Run #{K} for this plan. {Ready → `/execute-plan` | Caution/Stop → Path to Green below; update plan and `/pre-flight` again anytime}."*

---

## Iteration loop

```
/create-plan → /pre-flight → (edit plan) → /pre-flight → … → /execute-plan
                    ▲                              │
                    └──────── plan gaps ───────────┘
```

- Each `/pre-flight` run is independent — never say "you already ran pre-flight."
- Compare against prior reports; highlight **delta** in confidence and resolved blockers.
- **Stop** status is advisory — user may still edit plan and re-run immediately.

---

## Anti-Patterns

- Pushback when user runs `/pre-flight` again
- Auditing from plan excerpt while full file exists on disk
- Auditors without full plan text in the prompt
- Averaging confidence scores
- Discarding a gap because only one auditor found it
- Deliverable only in subagent thread

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | **main agent** (+ `pre-flight` auditors, iterative) |
| 4 | `/execute-plan` | main agent (+ `execute-plan` executor) |
| 5 | `/codereview` | main agent (+ `codereview` reviewers) |
