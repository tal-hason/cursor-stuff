# Agent Pipeline Contract

Shared flow for all pipeline slash commands. Every stage uses the same pattern:

1. **Main agent** owns the deliverable in the parent chat.
2. **Context Package** — full artifacts pasted into worker prompts, never excerpts.
3. **Worker subagents** — parallel where useful; `readonly` unless executing code.
4. **Thinking-tier models** for audit/review workers (no `*-fast` models).
5. **Memory bookends** — `memory_search` at start (mandatory); `memory_store` at end (mandatory). See [Memory contract](#memory-contract) below.

## Memory contract

Every pipeline command **MUST** call MCP `memory_search` as its first action and `memory_store` as its last action (after the deliverable is written). Hooks reinforce store on file write and session stop — they do not replace the explicit calls.

| Command | `memory_search` query (adapt to task) | `memory_store` `doc_type` | Primary artifact to index |
| :--- | :--- | :--- | :--- |
| `/architect-bootstrap` | workspace bootstrap, architecture, canvas brief, repo name | `canvas_brief` | `architect-brief.canvas.tsx` + chat summary |
| `/create-plan` | technical plan, feature area, workspace | `plan` | `{slug}.plan.md` full body |
| `/pre-flight` | pre-flight, plan name/slug, confidence | `preflight` | `*-Pre-Flight-Review_*.md` full body |
| `/execute-plan` | execution outcome, plan slug, repo | `execution` | `*-execution-outcome_*.md` + todo status summary |
| `/codereview` | code review, plan slug, branch/feature | `codereview` | `*-Code_Review_*.md` full body |
| `/eop` | continual learning, session learnings, workspace | `eop` | `*-session-digest_*.md` + AGENTS.md delta |

**Recall presentation:** Show hits with similarity > 0.6; if none, state explicitly. Carry hits into Context Packages.

**Store presentation:** `title` = filename or brief title; `content` = full artifact text (not a one-line summary); `workspace` = current workspace path.

**Mechanical reinforcement (optional):** Configure hooks (`afterFileEdit`, `subagentStop`, `stop`, `sessionStart`) to prompt `memory_store` calls on artifact writes and session boundaries. See `hooks.json` for examples.

## Flow

```
/architect-bootstrap
        │
        ▼  (Canvas brief + Jira discovery — optional)
/create-plan
        │
        ▼  (.plan.md + Jira issue created & plan attached)
/pre-flight  ◄──┐  (iterative — run as many times as needed)
        │       │
        ▼       │  (update plan → re-run pre-flight)
/execute-plan   │
        │       │
        ▼       │
/codereview ────┘  (if review finds plan gaps → edit plan → pre-flight again)
        │
        ▼  (terminal — captures learnings + compresses context)
/eop
```

## Stage summary

| # | Command | Actor | Workers | Primary deliverable |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent | **WHAT:** `ce-brainstorm` / `ce-ideate` / `ce-strategy` (main agent, Step 2.5 when vague). **WHERE:** scanners A–C + optional D–G, H–K | Canvas + situational brief (+ optional `docs/brainstorms/` requirements) |
| 2 | `/create-plan` | main agent | 3× evidence explorers | `{slug}.plan.md` + Jira issue created/linked (plan attached) |
| 3 | `/pre-flight` | main agent | 3× `pre-flight` auditors | `{slug}-Pre-Flight-Review_*.md` |
| 4 | `/execute-plan` | main agent | 1× `execute-plan` executor + 1× `execute-plan-tests` test writer (parallel) | Updated plan todos + code changes + tests + reconciliation |
| 5 | `/codereview` | main agent | Core R1–R6 (**R5/R6 security always** except docs-only) + conditional `ce-*` / PF auditors | `{slug}-Code_Review_*.md` |
| 6 | `/eop` | main agent | None (terminal) | `{slug}-session-digest_*.md` + `AGENTS.md` delta + Jira issue updated/closed (MR linked) |

## Iteration rules

| Loop | Behavior |
| :--- | :--- |
| **pre-flight → pre-flight** | Always allowed. New timestamped report each run. Include prior reports in Context Package. No pushback. |
| **pre-flight → create-plan** | Update plan from Path to Green, then re-run `/pre-flight`. |
| **execute-plan → pre-flight** | Allowed if execution reveals plan gaps (not a failure). |
| **codereview → pre-flight** | Allowed if review finds plan-level issues. |

## Execute gate (soft)

`/execute-plan` reads the **latest** `*-Pre-Flight-Review_*.md` for the plan slug:

- **≥ 90%** and not Stop → proceed
- **< 90%** or Stop → show blockers; user may update plan + re-run `/pre-flight`, or **explicitly override** to execute anyway
- **No report** → recommend `/pre-flight` first; user may override

## Worker subagents (by stage)

Main agent owns each deliverable. Dispatch **workers only** with the full Context Package for that stage.

| Stage | Command | Worker `subagent_type` (examples) | Reference docs |
| :--- | :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | `ce-repo-research-analyst`, `explore`, `ce-architecture-strategist`, compat lane, `ce-git-history-analyzer`, … | `references/architect-brief-canvas.md` |
| 2 | `/create-plan` | `ce-repo-research-analyst`, `explore`, `ce-correctness-reviewer` | `commands/create-plan.md` |
| 3 | `/pre-flight` | `pre-flight` (×3), optional `ce-security-lens-reviewer` | `agents/pre-flight.md` (output format) |
| 4 | `/execute-plan` | `execute-plan` + `execute-plan-tests` (parallel), `probe-runner` (Complex steps) | `agents/execute-plan.md`, `agents/execute-plan-tests.md` |
| 5 | `/codereview` | `codereview`, `ce-*` panel, `code-reviewer` | `agents/codereview.md` (R1 output format) |

**Ideation** (`ce-brainstorm`, `ce-ideate`, `ce-strategy`) runs in the **main agent** during bootstrap Step 2.5 — not as Task workers.

## Git workflow

After `/execute-plan` produces code changes, the git flow is:

```
work complete → branch out → push branch → create PR/MR → merge post review
```

| Step | When | Action |
| :--- | :--- | :--- |
| Branch out | After `/execute-plan` (code changes on disk) | Create a feature branch from the working state |
| Push branch | Before `/codereview` or after it passes | `git push -u origin HEAD` |
| Create PR/MR | After push | `gh pr create` or `glab mr create` with summary from plan/review |
| Merge | After code review approval | Merge via PR/MR (not direct push to main) |

**Rules:**
- Never push directly to `main`/`master` — always branch + PR/MR.
- The `/codereview` step reviews the diff on the branch. Push happens after review passes.
- Jira issue is created and plan attached during `/create-plan`; `/eop` captures the PR/MR URL, updates the Jira issue, and handles transition to Dev Complete/Closed.

## Command handoffs (end each stage with)

| After command | CTA |
| :--- | :--- |
| `/architect-bootstrap` | *"Bootstrap complete. Run `/create-plan` when ready."* |
| `/create-plan` | *"Plan written and attached to Jira issue {key}. Review the plan above. When approved, run `/pre-flight`."* |
| `/pre-flight` | *"Confidence {N}%. Run #{K}. {Ready → `/execute-plan` \| else → Path to Green, edit plan, `/pre-flight` again}."* |
| `/execute-plan` | *"Branch out and run `/codereview`"* (or re-run execute / pre-flight if blocked) |
| `/codereview` | Push branch + create PR/MR if clean; then *"Run `/eop` to close the pipeline."* Else fix findings or loop to `/pre-flight` |
| `/eop` | *"Pipeline complete. Session learnings captured. Digest at `{path}`."* (terminal) |
