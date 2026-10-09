---
name: eop
description: >-
  Stage 6 (End of Pipeline) of the Antigravity agent pipeline. Closes the pipeline session
  by capturing continual learnings into AGENTS.md, updating workspace documentation, creating
  session digests, and compressing context for future sessions. Use when closing out completed work.
---

# End of Pipeline

**Invoke via:** `/eop`

**You are the coordinator.** Execute Steps 1–6 in order. This is the **final stage** of the agent pipeline — it captures session learnings, updates docs, handles tracking, and compresses context for future sessions.

**Requires:** `/codereview` complete (or user explicitly closing the pipeline early).

**Pipeline:** See [Agent Pipeline Contract](../agent-pipeline/SKILL.md). This skill is terminal — no further stages.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | **Update project/folder docs** | Docs current (or no-op confirmed) |
| 3 | Main agent | **Tracking update & close** | Linked issues/PRs updated / transitioned |
| 4 | Main agent | **Continual Learning extraction** | `AGENTS.md` updated (or no-op confirmed) |
| 5 | Main agent | **Context compression** | Session digest written |
| 6 | Main agent | **`memory_store` NOW** | Indexed |

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work**:

```
query: continual learning, session learnings, {workspace or repo name}
limit: 5
```

Present hits with similarity > 0.6.

---

## Step 2: Update Project/Folder Docs

Review and update documentation artifacts affected by the session's work. Follow the documentation-first principle — docs should reflect the current state before the session closes.

### What to check:
1. **Task / repo `README.md`** — update with new features, changed APIs, commits/PRs.
2. **`CHANGELOG` or release notes** if the project uses them.
3. Push updated docs to memory with `doc_type: "docs"`.

---

## Step 3: Tracking & PR/MR Status Update

Update any issue tracking (e.g. Jira, GitHub issues) or PRs associated with this work. Add completion comment summarizing outcomes, test verification, and artifact links.

---

## Step 4: Continual Learning Extraction

Mine the **current session transcript** for durable, cross-session learnings. Update the workspace `AGENTS.md` file(s).

### What qualifies as a learning:
- **User preferences:** Commit style, review gate behavior, naming conventions
- **Workspace facts:** Epics, endpoint changes, repo paths, hardware constraints
- **Workflow patterns:** "Always do X before Y", "Skip Z when condition"
- **Tool/API discoveries:** Environment quirks, rate limits, schema details
- **Anti-patterns observed:** Approaches that failed and why

### Extraction procedure:
1. Scan the session for decisions, corrections, surprises, and repeated patterns.
2. Draft delta (grouped by section).
3. Deduplicate against existing `AGENTS.md`.
4. Append or update `AGENTS.md`.
5. Report the diff in chat.

---

## Step 5: Context Compression

Produce a **session digest** — a compressed summary that bridges this session to the next.

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

### Docs updated
- {doc path}: {what changed}

### Open threads (carry forward)
- {anything unresolved, deferred, or flagged for next session}

### Memory keys stored
- {titles of memory_store calls made during pipeline}
```

Write to: `.agents/digests/{slug}-session-digest_{YYYY-MM-DD_HHMM}.md`

---

## Step 6: Index (mandatory)

Call `memory_store` **after** digest is written:

- `title`: `eop-session-digest-{slug}`
- `content`: Full session digest text + list of AGENTS.md changes
- `doc_type`: `lesson_learned`
- `workspace`: current workspace path

---

## Closing CTA

End with:

> *"Pipeline complete. Session learnings captured in `AGENTS.md`. Digest at `{path}`. Context compressed and indexed for next session."*
