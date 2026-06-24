# Plan Execution

**Invoke via:** `/execute-plan`

**You are the coordinator.** Execute Steps 1–5 in order yourself. Main agent owns status and todo sync — see `commands/pipeline.md`.

Spawn **one** `execute-plan` worker in Step 3 with the full **Execution Context Package**. You present status in **this** conversation and update plan todo visibility.

**Requires:** `{slug}.plan.md` and ideally a latest `*-Pre-Flight-Review_*.md` (see `commands/pipeline.md` — soft gate).

**Pipeline:** `/pre-flight` → **this** → `/codereview`

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | Load plan + **latest** pre-flight report | Execution Context Package built |
| 2 | Main agent | Gate 0 (soft) | User informed; override OK |
| 3 | Executor | Dispatch `execute-plan` with full package | Worker completes or pauses on blockers |
| 4 | Main agent | Sync plan frontmatter todos | Status table in chat |
| 5 | Main agent | Outcome file + present | User sees todo progress |

---

## Step 1: Execution Context Package

Read from disk:

1. **Full `.plan.md`** (YAML frontmatter + entire body)
2. **Latest pre-flight report** — newest `~/.cursor/plans/{slug}-Pre-Flight-Review_*.md` by filename timestamp (if any exist)
3. Current todo statuses from plan frontmatter

```markdown
## Execution Context Package: {plan-slug}

### 1. Plan Identity
- Path, overview, workspace

### 2. Full Plan Text
(complete file)

### 3. Pre-Flight Status
- Latest report path + date
- Overall confidence, Ready/Caution/Stop
- Path to Green blockers (if any)
- Prior pre-flight reports summarized (if re-runs exist)

### 4. Execution State
- Todo list with current status (pending/in_progress/completed/blocked)
- Next actionable todo id

### 5. Prior Art
- Prior execution outcomes for this plan

### 6. Mission
Implement approved plan step by step. Update plan frontmatter todos. Spawn `probe-runner` only for Complex/probe steps. Propose commit messages. Do not skip verification.
```

**Gate:** Sections 1–2 complete before Step 3.

---

## Step 2: Gate 0 (Soft — No Pushback)

Using the **latest** pre-flight report:

| Condition | Main agent action |
| :--- | :--- |
| No pre-flight report | Recommend `/pre-flight`. **Do not refuse** — user may override to execute. |
| Confidence ≥ 90%, not Stop | State: "Pre-flight passed at {N}%. Proceeding." |
| Confidence < 90% or Stop | List blockers from Path to Green. Suggest: update plan → `/pre-flight` again. **User explicit override → proceed anyway.** |
| User re-ran `/pre-flight` since last execute | Use the newest report only — no lecture about prior runs. |

Iterative pre-flight is **expected**. Never block the user from running `/pre-flight` or `/execute-plan` again.

---

## Step 3: Dispatch Executor

One Task call: `subagent_type: execute-plan`.

Prompt MUST include the **entire Execution Context Package** (all 6 sections) + instruction to follow `agents/execute-plan.md`.

For **Complex** steps, executor may spawn `probe-runner` (background) with probe plan path — main agent tracks blocked todos.

**WAIT** for executor to finish or report blocked state before Step 4.

---

## Step 4: Sync Plan Todos

Ensure `~/.cursor/plans/{slug}.plan.md` frontmatter reflects actual todo statuses from execution.

---

## Step 5: Present

1. Write `~/.cursor/plans/{slug}-execution-outcome_YYYY-MM-DD_HHMM.md` (todo table, commits, blockers, next steps).
2. **Todo status table** in this conversation.
3. End with:
   - All completed → *"Run `/codereview`."*
   - Blocked on probes → *"Run `/execute-plan` again when probes complete."*
   - Plan gaps found → *"Update plan, optionally `/pre-flight`, then `/execute-plan` again."*

---

## Anti-Patterns

- Executor prompt with only plan path and no full plan text
- Ignoring latest pre-flight report when a newer one exists
- Refusing execution because an older pre-flight failed (use latest only)
- Deliverable only in executor subagent thread
- Skipping plan frontmatter todo updates

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors, iterative) |
| 4 | `/execute-plan` | **main agent** (+ `execute-plan` executor) |
| 5 | `/codereview` | main agent (+ `codereview` reviewers) |
