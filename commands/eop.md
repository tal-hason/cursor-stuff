# End of Pipeline

**Invoke via:** `/eop`

**You are the coordinator.** Execute Steps 1–6 in order. This is the **final stage** of the agent pipeline — it captures session learnings, updates docs, handles Jira tracking, and compresses context for future sessions.

**Requires:** `/codereview` complete (or user explicitly closing the pipeline early).

**Pipeline:** See `commands/pipeline.md`. This command is terminal — no further stages.

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | **Update project/folder docs** | Docs current (or no-op confirmed) |
| 3 | Main agent | **Jira issue check** | User confirmed (create/update/skip) |
| 4 | Main agent | **Continual Learning extraction** | `AGENTS.md` updated (or no-op confirmed) |
| 5 | Main agent | **Context compression** | Session digest written |
| 6 | Main agent | **`memory_store` NOW** | Indexed |

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work** (see `pipeline.md`):

```
query: continual learning, session learnings, {workspace or repo name}
limit: 5
```

Present hits with similarity > 0.6.

---

## Step 2: Update Project/Folder Docs

Review and update documentation artifacts affected by the session's work. Follow the documentation-first principle — docs should reflect the current state before the session closes.

### What to check

1. **Task folder `README.md`** — if the session worked within a task folder, update it with:
   - New issue keys, MR URLs, or commit SHAs produced
   - Status changes (e.g., "blueprint approved", "issues created", "MR merged")
   - Links to artifacts produced during the session

2. **Workspace-level tracking docs** — if the work affects a tracked area:
   - Endpoint config files, blueprint or coordination docs that reference the work

3. **Code repo docs** — if execution modified a code repo (check `Git` file for path):
   - `README.md` updates (new features, changed APIs, new env vars)
   - `CHANGELOG` or release notes if the project uses them

### Procedure

1. **Identify** which docs are affected based on the session's scope (read task folder, check `Git` file).
2. **Read current state** of each affected doc.
3. **Update** with session outcomes (keys, URLs, status, new sections).
4. **Push to memory** — for each updated doc, call `memory_store` with:
   - `doc_type: "docs"`
   - `service`: derive from repo/project name
   - `upsert: true` (living docs replace previous version)
   - `title`: filename
   - `content`: full updated file content
5. **Report** what was updated and stored (or state *"No doc updates needed."*).

If the session was purely exploratory (bootstrap only, no execution): skip this step.

---

## Step 3: Jira Issue Check

Verify whether the session's work relates to a tracked Jira issue, and whether Jira needs updating.

### Procedure

1. **Ask the user:**

   > "Is this work tracked in a Jira issue? Should I create or update one?"
   >
   > Options:
   > - **Update existing** — provide the issue key and I'll add a comment or transition
   > - **Create new** — I'll draft a task/story under the appropriate epic
   > - **Skip** — no Jira tracking needed for this work

2. **If "Update existing":**
   - Fetch the issue to confirm it's the right one
   - Add a comment summarizing what was done (artifacts, commits, outcomes)
   - Offer to transition (e.g., Dev Complete) if appropriate

3. **If "Create new":**
   - Ask which epic to parent under
   - Draft summary + description
   - Present draft for approval before creating

4. **If "Skip":** proceed to Step 4.

**Important:** Use your Jira MCP or REST API integration for reads and writes. Adapt to your project's Jira workflow and required fields.

---

## Step 4: Continual Learning Extraction

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

If the session produced no durable learnings: state *"No new learnings to extract."* and proceed to Step 5.

---

## Step 5: Context Compression

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

### Docs updated
- {doc path}: {what changed}

### Jira tracking
- {issue key}: {action taken (created/updated/commented/transitioned)} — or "Skipped"

### Open threads (carry forward)
- {anything unresolved, deferred, or flagged for next session}

### Memory keys stored
- {titles of memory_store calls made during pipeline}
```

**Write to:** `~/.cursor/plans/{slug}-session-digest_{YYYY-MM-DD_HHMM}.md`

If only partial pipeline was run (e.g., no plan, just bootstrap), include only applicable sections.

---

## Step 6: Index (mandatory)

Call `memory_store` **after** digest is written:

- `title`: `eop-session-digest-{slug}` or `eop-{workspace-slug}-{date}`
- `content`: Full session digest text + list of AGENTS.md changes
- `doc_type`: `lesson_learned` (session digests are durable learnings)
- `workspace`: current workspace path
- `tags`: `["eop", "{workspace-slug}"]`

---

## Closing CTA

End with:

> *"Pipeline complete. Session learnings captured in `AGENTS.md`. Digest at `{path}`. Context compressed and indexed for next session."*

---

## Anti-Patterns

- Storing transient/ephemeral state as "learnings" (branch names, one-off dates)
- Skipping context compression when session was productive
- Writing duplicate entries already in `AGENTS.md`
- Skipping `memory_search` or `memory_store`
- Overwriting existing learnings instead of appending/updating
- Creating Jira issues without user approval
- Updating docs with speculative/planned work that wasn't actually executed
- Skipping the Jira check when the session clearly relates to a tracked epic

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors) |
| 4 | `/execute-plan` | main agent (+ executor) |
| 5 | `/codereview` | main agent (+ specialized review panel) |
| 6 | `/eop` | **main agent** (terminal — no workers) |
