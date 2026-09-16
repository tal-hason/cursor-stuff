# Plan Execution

**Invoke via:** `/execute-plan`

**You are the coordinator.** Execute Steps 1–6 in order yourself. Main agent owns status and todo sync — see `commands/pipeline.md`.

Spawn **two workers in parallel** in Step 4 — `execute-plan` (code) and `execute-plan-tests` (tests) — both with the full **Execution Context Package**. You present status in **this** conversation, run reconciliation, and update plan todo visibility.

**Requires:** `{slug}.plan.md` and ideally a latest `*-Pre-Flight-Review_*.md` (see `commands/pipeline.md` — soft gate).

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

Call `memory_search` **before any other work** (see `pipeline.md`):

`query`: execution outcome, plan slug, repo · `limit: 5` · present hits > 0.6

---

## Step 2: Execution Context Package (by Reference)

Read from disk:

1. **Plan path** (`.plan.md`)
2. **Latest pre-flight report path** — newest `~/.cursor/plans/{slug}-Pre-Flight-Review_*.md` by filename timestamp (if any exist)
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
- Prior pre-flight reports summarized (if re-runs exist)

### 3. Execution State
- Todo list with current status (pending/in_progress/completed/blocked)
- Next actionable todo id

### 4. Prior Art
- Memory hits from Step 1
- Prior execution outcomes for this plan

### 5. Mission
Implement approved plan step by step. Update plan frontmatter todos. Spawn `probe-runner` only for Complex/probe steps. Propose commit messages. Do not skip verification.
```

**Gate:** Sections 1–2 complete before Step 4.

---

## Step 3: Gate 0 (Soft — No Pushback)

Using the **latest** pre-flight report:

| Condition | Main agent action |
| :--- | :--- |
| No pre-flight report | Recommend `/pre-flight`. **Do not refuse** — user may override to execute. |
| Confidence ≥ 90%, not Stop | State: "Pre-flight passed at {N}%. Proceeding." |
| Confidence < 90% or Stop | List blockers from Path to Green. Suggest: update plan → `/pre-flight` again. **User explicit override → proceed anyway.** |
| User re-ran `/pre-flight` since last execute | Use the newest report only — no lecture about prior runs. |

Iterative pre-flight is **expected**. Never block the user from running `/pre-flight` or `/execute-plan` again.

---

## Step 4: Dispatch Executor + Test Writer (Parallel)

**Two Task calls in one message.** Both agents receive the **Execution Context Package by Reference** (all 5 sections).

| Agent | `subagent_type` | Agent doc | Mission |
| :--- | :--- | :--- | :--- |
| **Code Executor** | `execute-plan` | `agents/execute-plan.md` | Implement plan steps — write production code |
| **Test Writer** | `execute-plan-tests` | `agents/execute-plan-tests.md` | Write tests from Step 7 Test Specification — independently |

### Dispatch rules

1. Both dispatched in the **same message** (parallel).
2. Both receive the **Execution Context Package by Reference** — pass plan path, do not dump entire plan body into both prompts.
3. Both prompts MUST enforce the **Communication Contract**: strict telegraphic / caveman format, zero conversational filler, output status and actions directly.
4. The Test Writer prompt MUST include: *"You are running in parallel with a code executor. Do not write implementation code. Write tests from the plan's Test Specification table only."*
5. For **Complex** steps, executor may spawn `probe-runner` — test writer skips those rows (flags as "pending probe").

**WAIT** for **both** agents to finish or report blocked state before Step 5.

---

## Step 5: Reconciliation (TDD Gate)

After both agents complete, the main agent runs the project's test suite against the combined output:

| Check | Command | Expected |
| :--- | :--- | :--- |
| Test syntax | lint / typecheck on test files | pass |
| Test execution | project test runner | pass (or known-failing with reason) |
| Coverage map | test writer's report vs plan spec table | every spec row covered |

### Reconciliation outcomes

| Outcome | Action |
| :--- | :--- |
| **All tests pass** | Tests validate implementation. Proceed to Step 6. |
| **Tests fail — implementation bug** | Fix in code (minor), or flag as executor gap for `/codereview`. |
| **Tests fail — test targets wrong interface** | Test writer assumed a different API shape. Adjust tests to match actual implementation. Note the divergence — it signals plan ambiguity. |
| **Spec rows uncovered** | Test writer flagged gaps. Decide: add tests now, or carry as known gaps into `/codereview`. |

**Report divergences in chat.** Divergence between test writer and executor is valuable signal — it means the plan's specification was ambiguous at that point. The codereview step should evaluate whether the plan or the implementation needs correction.

---

## Step 6: Sync Plan Todos

Ensure `~/.cursor/plans/{slug}.plan.md` frontmatter reflects actual todo statuses from execution.

---

## Step 7: Present and Index (mandatory)

1. Write `~/.cursor/plans/{slug}-execution-outcome_YYYY-MM-DD_HHMM.md` (todo table, commits, blockers, next steps, **reconciliation results**).
2. **Todo status table** in this conversation.
3. **Reconciliation summary** — tests passed/failed/diverged, spec coverage.
4. Call `memory_store` **NOW**: `title` = outcome filename, `content` = **full outcome file body**, `doc_type: execution`, `workspace` = current path.
5. End with:
   - All completed + tests pass → *"Run `/codereview`."*
   - Blocked on probes → *"Run `/execute-plan` again when probes complete."*
   - Reconciliation failures unresolved → *"Fix divergences, then run `/codereview`."*
   - Plan gaps found → *"Update plan, optionally `/pre-flight`, then `/execute-plan` again."*

---

## Anti-Patterns

- Executor prompt with only plan path and no full plan text
- Ignoring latest pre-flight report when a newer one exists
- Refusing execution because an older pre-flight failed (use latest only)
- Deliverable only in executor subagent thread
- Skipping plan frontmatter todo updates
- Skipping `memory_search` or `memory_store`
- Dispatching only the code executor without the test writer (both are mandatory)
- Sharing implementation code with the test writer (defeats independent specification)
- Skipping reconciliation when tests fail ("they'll fix it in review")
- Silently adjusting tests to match implementation without noting the divergence
- Test writer and executor dispatched sequentially instead of in parallel

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors, iterative) |
| 4 | `/execute-plan` | **main agent** (+ `execute-plan` executor + `execute-plan-tests` test writer) |
| 5 | `/codereview` | main agent (+ `codereview` reviewers) |
