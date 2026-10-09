---
name: codereview
description: >-
  Stage 5 of the Antigravity agent pipeline. Convenes a multi-reviewer specialist panel
  (Principal Architect, security lenses, correctness auditors) to review staged or committed
  diffs against architectural rules and safety invariants. Use before pushing or merging code.
---

# Code Review

**Invoke via:** `/codereview`

**You are the coordinator.** Execute Steps 1–8 in order yourself. Main agent owns the deliverable — see [Agent Pipeline Contract](../agent-pipeline/SKILL.md).

Spawn a **Review Panel** of specialized subagents in Step 5 (`readonly: true`). You merge findings and run verification gates in **this** conversation.

**Requires:** Staged or committed changes from `/execute-plan` (or user-provided diff scope).

**Pipeline:** See [Agent Pipeline Contract](../agent-pipeline/SKILL.md). Plan-level gaps → update plan → `/pre-flight` (iterative).

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | Scan diff + `@ai-shebang` on touched files | Modified file list |
| 3 | Main agent | Build **Code Review Context Package** | Full plan + diff attached |
| 4 | Main agent | **Review Panel triage** + read applicable skills | Panel table published |
| 5 | Review panel (parallel) | Dispatch specialized reviewers | All returned |
| 6 | Main agent | Pessimistic merge + correlation | Unified report draft |
| 7 | Main agent | Verification gate (test, typecheck, build) | Pass or failures listed |
| 8 | Main agent | Write report, present in chat, **`memory_store` NOW** | User sees merged review |

**Next (if clean):** push + Jira Dev Complete per plan/issue.

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work**:

`query`: code review, plan slug, branch/feature · `limit: 5` · present hits > 0.6

---

## Step 2: Diff Scope

1. Identify all modified files (`git diff --staged` or branch diff).
2. Read `@ai-shebang` on every touched file.
3. List consumers/callers of modified exports (initial pass).
4. Estimate diff size and domains touched.
5. **Security surface scan** — flag if diff touches: auth/authz, secrets/env, user input parsing, public endpoints, crypto/TLS, IAM/RBAC, SQL/command construction, file/path handling.

---

## Step 3: Code Review Context Package (by Reference)

**Main agent only.** Build the package by reference:

```markdown
## Code Review Context Package: {plan-slug}

### 1. Plan Identity
- Plan path (read via `view_file`), overview, workspace
- Pre-flight report path/summary if available

### 2. Execution Scope
- Which plan todos were implemented
- Commits or summary of changes

### 3. Diff Scope (by Reference)
- Git range: `git diff <base>...HEAD`
- Modified files (absolute paths) and line counts
- Hexagonal layer per file (Domain / Port / Adapter / Infrastructure)

### 4. Consumer Map (initial)
- Callers/consumers from Step 2

### 5. Prior Art
- Memory hits from Step 1

### 6. Review Mission
Review changes against plan intent. System-wide impact, contracts, zero deferred debt. Do not rubber-stamp.
```

---

## Step 4: Review Panel Triage

Select reviewers based on diff signals. Publish the panel in chat before dispatching.

### Core panel (always dispatch)

| ID | Role | Model | Lens |
| :--- | :--- | :--- | :--- |
| **R1** | Principal Reviewer | `inherit` / `pro` | Principal review — architecture, contracts, downstream impact (`agents/codereview.md`) |
| **R2** | Correctness Lens | `inherit` / `pro` | Logic, edge cases, state bugs |
| **R3** | Maintainability Lens | `flash` | Structure, coupling, naming, complexity |
| **R4** | Plan Alignment Lens | `inherit` / `pro` | Plan alignment — implementation vs plan todos & evidence |
| **R5** | Security Vulnerability Reviewer | `inherit` / `pro` | Exploitable diff security — auth, injection, validation |
| **R6** | Security Sentinel | `flash` | Security audit — secrets, credentials, unsafe crypto, log leakage |

**Security core is mandatory** for every `/codereview` after `/execute-plan`. Only skip R5+R6 if the diff is **docs-only**.

### Conditional panel

- **Testing Reviewer (C1):** Mandatory after `/execute-plan` (TDD gate)
- **API Contract Reviewer (C2):** API routes, types, serialization
- **Reliability Reviewer (C4):** Retries, timeouts, jobs, error handling
- **Performance Reviewer (C5):** Queries, loops, caching, I/O-heavy paths

---

## Step 5: Parallel Reviews

**WAIT** for all panel members before Step 6. Dispatch in parallel with `readonly: true`.

Each prompt MUST include:
1. **Code Review Context Package by Reference**
2. **Communication Contract:** strict telegraphic style (caveman), zero conversational filler
3. **Reviewer role and lens**
4. **Mission:** return structured findings only
5. **Signature:** reviewer signs findings with their ID (R1, R5, etc.)

---

## Step 6: Merge (Pessimistic)

| Rule | Policy |
| :--- | :--- |
| Risk level | **Highest** across reviewers |
| Cynefin | **More complex** wins |
| Findings | **Union** all — tag with reviewer ID |
| Severity | **Highest** wins |
| Downstream impact | **Union** consumers |
| Security findings | Any exploitable issue = **HIGH** unless proven false positive |

Include dedicated **Security section** and **Reviewer agreement matrix**.

---

## Step 7: Verification Gate

| Check | Command | Result |
| :--- | :--- | :--- |
| Unit tests | project test command | pass/fail |
| Typecheck | tsc/mypy/etc. | pass/fail |
| Build | build command | pass/fail |
| Test spec coverage | Compare test files vs plan Step 7a table | all covered / gaps listed |
| TDD divergence | Review reconciliation summary | resolved / unresolved |

Do NOT approve push if any check fails.

---

## Step 8: Write, Present, Index

Path: `.agents/plans/{plan-slug}-Code_Review_YYYY-MM-DD_HHMM.md`

1. **Paste full report in this conversation.**
2. Call `memory_store` **NOW**: full report body, `doc_type: codereview`.
3. If clean: proceed to push branch and PR/MR.
