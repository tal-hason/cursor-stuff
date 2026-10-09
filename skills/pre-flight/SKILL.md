---
name: pre-flight
description: >-
  Stage 3 of the Antigravity agent pipeline. Audits an implementation plan (.plan.md)
  for confidence, boundary violations, integration risks, and Cynefin alignment before touching
  production code. Soft gate ≥ 90%. Use iteratively to validate and refine plans prior to execution.
---

# Pre-Flight Review

**Invoke via:** `/pre-flight`

**You are the coordinator.** Execute Steps 1–6 in order yourself. Main agent owns the deliverable — see [Agent Pipeline Contract](../agent-pipeline/SKILL.md).

Spawn **`pre-flight` auditors** in Step 3 (`readonly: true`). You merge their output and author the unified report in **this** conversation.

**Requires:** A `.plan.md` from `/create-plan` (path or @-mention).

**Iterative:** Run this skill **as many times as needed** — each run writes a new timestamped report. Re-runs are encouraged, not penalized.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | Build **Pre-Flight Context Package** | Full plan loaded — not an excerpt |
| 3 | Auditors (parallel) | Dispatch `pre-flight` subagents | All auditors returned |
| 4 | Main agent | Pessimistic merge + correlation | Report draft ready |
| 5 | Main agent | Write `*-Pre-Flight-Review_*.md` | File on disk |
| 6 | Main agent | Present dashboard + **`memory_store` NOW** | User sees confidence + path to green |

**Soft gate for `/execute-plan`:** ≥ 90% and not Stop → ready; otherwise Path to Green or user override.

**Next:** `/execute-plan` → `/codereview` (or edit plan + run `/pre-flight` again)

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work**:

`query`: pre-flight, plan name/slug, same feature/workspace · `limit: 5` · present hits > 0.6

---

## Step 2: Pre-Flight Context Package (by Reference)

**Main agent only.** Build this package — auditors receive the **package by reference** with exact file paths, avoiding prompt token bloat from duplicating large plan files:

```markdown
## Pre-Flight Context Package: {plan-slug}

### 1. Plan Identity
- **Path:** absolute path to `.plan.md` (read directly via `view_file`)
- **Name / overview:** from YAML frontmatter
- **Workspace:** current workspace root

### 2. Plan Structure Summary
- Numbered atomic steps with Cynefin tags from the plan
- Complex / probe-required steps highlighted
- Files referenced in the plan (absolute paths)

### 3. Prior Art & Iteration History
- Relevant `memory_search` hits from Step 1
- Prior `*-Pre-Flight-Review_*.md` for this plan slug (summarize confidence trend)

### 4. Audit Mission
Stress-test the plan above. Classify each step (Cynefin), score confidence, find gaps. Do not execute code. Read the plan from its path directly.
```

**Gate:** Package complete before Step 3. Never dispatch auditors with only the user’s last message.

---

## Step 3: Parallel Audits

**WAIT** for all auditors before Step 4.

Dispatch **3** `pre-flight` subagents in parallel. `readonly: true`.

| Auditor | Model | Lens |
| :--- | :--- | :--- |
| **A** | `inherit` / `pro` | Cynefin + architecture depth, integration patterns |
| **B** | `flash` | Gap analysis, missing context, plan completeness |
| **C** | `inherit` / `pro` | Contracts, platform abstractions, edge cases |

**Optional security lane:** When the plan touches auth/authz, secrets, public endpoints, PII, or trust boundaries — dispatch a security lens reviewer in parallel.

### Each Task prompt MUST include:

1. **Pre-Flight Context Package by Reference** (pass plan path)
2. **Mission:** execute the `pre-flight` agent procedure; return structured Pre-Flight Dashboard only
3. **Communication Contract:** strict telegraphic style (caveman), zero greetings/filler/intros, start directly with `### 1. Confidence Dashboard`
4. **Output contract:** structured audit format

---

## Step 4: Merge (Pessimistic)

| Rule | Policy |
| :--- | :--- |
| Confidence per task | **Minimum** across auditors |
| Overall confidence | **Minimum** across auditors |
| Cynefin | **More complex** wins |
| Gaps / blockers | **Union** — one auditor flag = real gap |
| Contradictions | Flag for user; do not silently resolve |
| Path to Green | Merge, dedupe, blockers first |

**Cross-issue correlation:** Collapse findings that share one root cause before finalizing. Produce **Auditor agreement matrix**.

---

## Step 5: Write Report

Path: `.agents/plans/{plan-slug}-Pre-Flight-Review_YYYY-MM-DD_HHMM.md`

Required sections:
1. Confidence Dashboard (overall %, Ready/Caution/Stop, top blockers)
2. Task-by-Task Analysis (min confidence, agreement column)
3. Integration Risk Matrix
4. Platform Abstraction Audit (if applicable)
5. Gap Analysis (< 95% tasks — ambiguity, missing context, risk)
6. Security Threat Model (if security lane ran)
7. Auditor Disagreements (if any)
8. Path to Green (blockers + suggestions)

---

## Step 6: Present and Index

1. **Paste the full Pre-Flight Dashboard in this conversation.**
2. Call `memory_store` **NOW**: `title` = report filename, `content` = full report body, `doc_type: preflight`.
3. State outcome:
   - *"Confidence {N}%. Run #{K} for this plan. {Ready → `/execute-plan` | Caution/Stop → Path to Green below; update plan and `/pre-flight` again anytime}."*
