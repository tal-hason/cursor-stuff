# Agent Pipeline Contract

Shared flow for all pipeline slash commands. Every stage uses the same pattern:

1. **Main agent** owns the deliverable in the parent chat.
2. **Context Package** — full artifacts pasted into worker prompts, never excerpts.
3. **Worker subagents** — parallel where useful; `readonly` unless executing code.
4. **Thinking-tier models** for audit/review workers (no `*-fast` models).

## Flow

```
/architect-bootstrap
        │
        ▼  (Canvas brief + Jira discovery — optional)
/create-plan
        │
        ▼  (.plan.md)
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
| 2 | `/create-plan` | main agent | 3× evidence explorers | `{slug}.plan.md` |
| 3 | `/pre-flight` | main agent | 3× `pre-flight` auditors | `{slug}-Pre-Flight-Review_*.md` |
| 4 | `/execute-plan` | main agent | 1× `execute-plan` executor | Updated plan todos + code changes |
| 5 | `/codereview` | main agent | Core R1–R6 (**R5/R6 security always** except docs-only) + conditional `ce-*` / PF auditors | `{slug}-Code_Review_*.md` |
| 6 | `/eop` | main agent | None (terminal) | `{slug}-session-digest_*.md` + `AGENTS.md` delta |

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
| 4 | `/execute-plan` | `execute-plan`, `probe-runner` (Complex steps) | `agents/execute-plan.md` |
| 5 | `/codereview` | `codereview`, `ce-*` panel, `code-reviewer` | `agents/codereview.md` (R1 output format) |

**Ideation** (`ce-brainstorm`, `ce-ideate`, `ce-strategy`) runs in the **main agent** during bootstrap Step 2.5 — not as Task workers.

## Command handoffs (end each stage with)

| After command | CTA |
| :--- | :--- |
| `/architect-bootstrap` | *"Bootstrap complete. Run `/create-plan` when ready."* |
| `/create-plan` | *"Review the plan above. When approved, run `/pre-flight`."* |
| `/pre-flight` | *"Confidence {N}%. Run #{K}. {Ready → `/execute-plan` \| else → Path to Green, edit plan, `/pre-flight` again}."* |
| `/execute-plan` | *"Run `/codereview`"* (or re-run execute / pre-flight if blocked) |
| `/codereview` | Push if clean; then *"Run `/eop` to close the pipeline."* Else fix findings or loop to `/pre-flight` |
| `/eop` | *"Pipeline complete. Session learnings captured. Digest at `{path}`."* (terminal) |
