# Cursor Agent Pipeline — AGENTS.md

Workspace-specific memory for the agent pipeline. This file is maintained by `/eop` (End of Pipeline) and the continual-learning hook.

---

## Agent pipeline (stable)

**Canonical contract:** `commands/pipeline.md`

**Flow:** `/architect-bootstrap` → `/create-plan` → `/pre-flight` → `/execute-plan` → `/codereview` → `/eop`

| Command | Main agent owns | Workers |
| :--- | :--- | :--- |
| `/architect-bootstrap` | Canvas + situational brief | Scan panel A–K; ideation in main agent (Step 2.5) |
| `/create-plan` | `.plan.md` | 3× explorers (`ce-repo-research-analyst`, `explore`, `ce-correctness-reviewer`) |
| `/pre-flight` | Pre-Flight Dashboard | 3× `pre-flight` (+ optional `ce-security-lens-reviewer`) |
| `/execute-plan` | Status + todo sync + reconciliation | 1× `execute-plan` + 1× `execute-plan-tests` (parallel) |
| `/codereview` | Code Review report | R1–R6 core + conditional `ce-*` panel |
| `/eop` | Session digest + AGENTS.md delta | None (terminal) |

**Correct Cursor mode per command:**

| Command | Mode |
| :--- | :--- |
| `/architect-bootstrap` | Agent or Ask (Ask for fresh ideas) |
| `/create-plan` | Plan |
| `/pre-flight` | Agent or Plan |
| `/execute-plan` | Agent |
| `/codereview` | Agent |
| `/eop` | Agent |

**Rules:** `memory_search` first; full Context Packages in worker prompts; `memory_store` last; thinking-tier models for audit/review workers.

**References (not subagents):** `references/architect-brief-canvas.md`

**Team how-to:** `docs/pipeline-howto.md` — onboarding guide for the pipeline slash commands.

**`/pre-flight` is iterative** — new timestamped report each run; `/execute-plan` uses latest; soft gate ≥ 90%.

---

## Learned preferences

_Add stable, cross-session preferences below. The continual-learning updater appends here._

- Commit only when explicitly confirmed (e.g., "yes" after being prompted).
- When documenting pipeline commands or modes, describe behavior factually — don't editorialize or characterize choices without the user saying so.
- Preferred pipeline workflow uses two sessions: Session 1 (exploration) scans the workspace and converges on a solution, then outputs a crafted prompt; Session 2 (execution) starts fresh with distilled intent for `/architect-bootstrap` onward — memory bridges the gap.

### Auto-merge + AI doc-reviewer CI risk

When an MR is set to GitLab's "merge when pipeline succeeds" and its CI pipeline includes an
AI doc-reviewer with commit/auto-publish capability, a green pipeline does not mean the
auto-committed content is correct — each review pass can introduce a fresh regression that
gets merged before a human reviews it, and the loop can repeat (a "fix" pass reverting an
earlier correct fix). When babysitting this kind of MR: diff every auto-commit yourself
before trusting the next green pipeline, and prefer to disable auto-merge on any follow-up
fix MR targeting the same review pipeline until the underlying tool bug is confirmed
root-caused.
