# End of Pipeline

**Invoke via:** `/eop`

**You are the coordinator.** Execute Steps 1–2 in order. This is the **final stage** of the agent pipeline — it captures session learnings and compresses context for future sessions.

**Requires:** `/codereview` complete (or user explicitly closing the pipeline early).

**Pipeline:** See `commands/pipeline.md`. This command is terminal — no further stages.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **Continual Learning extraction** | `AGENTS.md` updated (or no-op confirmed) |
| 2 | Main agent | **Context compression** | Session digest written |

---

## Step 1: Continual Learning Extraction

Mine the **current session transcript** for durable, cross-session learnings. Update the appropriate `AGENTS.md` file(s).

### What qualifies as a learning

| Category | Example |
| :--- | :--- |
| **User preferences** | Commit style, review gate behavior, naming conventions |
| **Workspace facts** | New standing epics, endpoint changes, repo paths |
| **Workflow patterns** | "Always do X before Y", "Skip Z when condition" |
| **Tool/API discoveries** | "Field X is actually named Y in Cloud", rate limits |
| **Anti-patterns observed** | Approaches that failed and why |

### What does NOT qualify

- Transient state (today's date, current branch, one-off flags)
- Task-specific details already captured in plan/review artifacts
- Opinions not validated by evidence in the session

### Extraction procedure

1. **Scan the session** for decisions, corrections, surprises, and repeated patterns.
2. **Draft delta** — new bullet points or updates to existing ones. Group by section (`Learned User Preferences`, `Learned Workspace Facts`, or the pipeline-specific subsection).
3. **Deduplicate** — check existing `AGENTS.md` content; skip if already present.
4. **Apply** — append or update the relevant `AGENTS.md`:
   - `~/.cursor/AGENTS.md` for cross-workspace learnings
   - Workspace-local `AGENTS.md` for repo-specific facts
5. **Report** — show the user what was added/changed (diff-style).

If the session produced no durable learnings: state *"No new learnings to extract."* and proceed to Step 2.

---

## Step 2: Context Compression

Produce a **session digest** — a compressed summary that bridges this session to the next. This is the handoff artifact.

### Digest structure

```markdown
## Session Digest: {date} — {one-line intent}

### Pipeline stages completed
- /architect-bootstrap: {outcome}
- /create-plan: {plan slug}
- /pre-flight: {confidence%, run count}
- /execute-plan: {outcome}
- /codereview: {verdict}

### Key decisions made
- {decision 1}
- {decision 2}

### Artifacts produced
| Artifact | Path |
| :--- | :--- |
| Plan | `{path}` |
| Pre-flight | `{path}` |
| Code review | `{path}` |
| Canvas | `{path}` |

### Open threads (carry forward)
- {anything unresolved, deferred, or flagged for next session}
```

**Write to:** `~/.cursor/plans/{slug}-session-digest_{YYYY-MM-DD_HHMM}.md`

If only partial pipeline was run (e.g., no plan, just bootstrap), include only applicable sections.

---

## Closing CTA

End with:

> *"Pipeline complete. Session learnings captured in `AGENTS.md`. Digest at `{path}`."*

---

## Anti-Patterns

- Storing transient/ephemeral state as "learnings" (branch names, one-off dates)
- Skipping context compression when session was productive
- Writing duplicate entries already in `AGENTS.md`
- Overwriting existing learnings instead of appending/updating

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors) |
| 4 | `/execute-plan` | main agent (+ executor) |
| 5 | `/codereview` | main agent (+ specialized review panel) |
| 6 | `/eop` | **main agent** (terminal — no workers) |
