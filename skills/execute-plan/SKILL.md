---
name: execute-plan
description: >-
  Stage 4 of the Antigravity agent pipeline. Executes an approved implementation plan
  using parallel TDD (code executor + test writer), running safe-to-fail probes for complex
  steps, and reconciling test results. Use to build and verify planned changes.
---

# Plan Execution

**Invoke via:** `/execute-plan`

**You are the coordinator.** Execute Steps 1–6 in order yourself. Main agent owns status and todo sync — see [Agent Pipeline Contract](../agent-pipeline/SKILL.md).

Spawn **two workers in parallel** in Step 4 — `execute-plan` (code) and `execute-plan-tests` (tests) — both with the full **Execution Context Package**. You present status in **this** conversation, run reconciliation, and update plan todo visibility.

**Requires:** `{slug}.plan.md` and ideally a latest `*-Pre-Flight-Review_*.md` (soft gate).

**Pipeline:** `/pre-flight` → **this** → `/codereview`

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | Load plan + **latest** pre-flight report | Execution Context Package built |
| 3 | Main agent | Gate 0 (soft) | User informed; override OK |
| 4 | Executor + Test Writer | Dispatch **both agents in parallel** with full package | Both complete or pause on blockers |
| 5 | Main agent | **Reconciliation** — run tests against code | Pass/fail table in chat |
| 6 | Main agent | Sync plan frontmatter todos | Status table in chat |
| 7 | Main agent | Outcome file + **`memory_store` NOW** | User sees todo progress |

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work**:

`query`: execution outcome, plan slug, repo · `limit: 5` · present hits > 0.6

---

## Step 2: Execution Context Package (by Reference)

Read from disk:
1. **Plan path** (`.plan.md`)
2. **Latest pre-flight report path** — newest `*-Pre-Flight-Review_*.md` by filename timestamp (if any exist)
3. Current todo statuses from plan frontmatter

```markdown
## Execution Context Package: {plan-slug}

### 1. Plan Identity
- Path: absolute path to `.plan.md` (read directly via `view_file`)
- Overview, workspace

### 2. Pre-Flight Status
- Latest report path + date
- Overall confidence, Ready/Caution/Stop
- Path to Green blockers (if any)

### 3. Execution State
- Todo list with current status (pending/in_progress/completed/blocked)
- Next actionable todo id

### 4. Prior Art
- Memory hits from Step 1
- Prior execution outcomes for this plan

### 5. Mission
Implement approved plan step by step. Update plan frontmatter todos. Spawn `probe-runner` only for Complex/probe steps. Propose commit messages. Do not skip verification.
```

---

## Step 3: Gate 0 (Soft — No Pushback)

Using the **latest** pre-flight report:

| Condition | Main agent action |
| :--- | :--- |
| No pre-flight report | Recommend `/pre-flight`. Do not refuse — user may override to execute. |
| Confidence ≥ 90%, not Stop | State: "Pre-flight passed at {N}%. Proceeding." |
| Confidence < 90% or Stop | List blockers from Path to Green. Suggest update plan → `/pre-flight` again. User explicit override → proceed anyway. |
| User re-ran `/pre-flight` since last execute | Use newest report only. |

---

## Step 4: Red-First Phased Dispatch (Executable Specifications First)

Follow Farley's 3 rules for AI execution:
1. **Red Before Green**: Run tests before writing implementation code; failure is the only proof the test detects defects.
2. **Anti-Tampering Contract**: Test files are immutable setpoints. Coding agents must not modify tests to make them pass.
3. **Small Verifiable Batches**: Step-by-step implementation against the locked test harness.

### Phase 4A: Test Specifier (`execute-plan-tests`)
1. Dispatch `execute-plan-tests` with the Execution Context Package by reference.
2. The Test Specifier authors the 4-layer acceptance tests (Intent, DSL, Protocol Drivers, SUT targets) from plan Step 7.
3. **Red Failure Proof**: The Test Specifier runs the test suite and reports explicit failure output (RED).
4. Main agent verifies that test files are committed or sealed as the contract setpoint.

### Phase 4B: Code Executor (`execute-plan`)
1. Dispatch `execute-plan` with the failing test diagnostics and plan path.
2. **Anti-Tampering Rule Enforced**: The prompt strictly forbids editing any test files.
3. Executor iterates in small batches on production code until all acceptance tests turn GREEN.

---

## Step 5: Reconciliation & Contract Integrity Gate

After both phases complete, the main agent verifies contract integrity:

| Check | Command | Expected |
| :--- | :--- | :--- |
| Contract Integrity | `git diff --name-only` on test files | Test files unchanged during coder phase |
| Test Execution | project test runner | 100% pass |
| Spec Coverage | test report vs plan Step 7 scenarios | every scenario covered |

### Reconciliation outcomes

| Outcome | Action |
| :--- | :--- |
| **All tests pass & contract intact** | Tests validate implementation cleanly. Proceed to Step 6. |
| **Tests fail — implementation bug** | Re-dispatch `execute-plan` worker to fix implementation code (main agent MUST NOT patch code directly). |
| **Test was tampered with by executor** | Revert test mutations; re-dispatch executor with strict warning to fix production code only. |
| **Spec rows uncovered** | Dispatch `execute-plan-tests` to add missing scenarios before proceeding. |

---

## Step 6: Sync Plan Todos

Ensure `.plan.md` frontmatter reflects actual todo statuses from execution.

---

## Step 7: Present and Index (mandatory)

1. Write `*-execution-outcome_YYYY-MM-DD_HHMM.md` (todo table, commits, blockers, next steps, reconciliation results).
2. Present **Todo status table** in this conversation.
3. Present **Reconciliation summary** — tests passed/failed/diverged, spec coverage.
4. Call `memory_store` **NOW**: `title` = outcome filename, `content` = full outcome file body, `doc_type: execution`.
5. End with:
   - All completed + tests pass → *"Run `/codereview`."*
   - Blocked on probes → *"Run `/execute-plan` again when probes complete."*
   - Plan gaps found → *"Update plan, optionally `/pre-flight`, then `/execute-plan` again."*
