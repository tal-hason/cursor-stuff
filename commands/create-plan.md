# Technical Plan

**Invoke via:** `/create-plan`

**You are the coordinator.** Execute Steps 1–9 in order yourself. Main agent owns the deliverable — see `commands/pipeline.md`.

The only subagents you may spawn are the **3 evidence explorers** in Step 3 (`readonly: true`). You merge their output and author the final plan in **this** conversation.

**Pipeline:** See `commands/pipeline.md`. **Prior stage:** `/architect-bootstrap` (optional — carry Canvas brief into Step 2).

## Execution checklist

| Step | Who | Action | Gate before next step |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** + present hits | Hits shown (or "none above 0.6") |
| 2 | Main agent | Write **Exploration Design Brief** + Mermaid map | Brief complete — ready to attach to explorer prompts |
| 3 | 3 explorers (parallel) | Dispatch A, B, C via Task tool | **All 3 completed** (or A+C if 2-model fallback) |
| 4 | Main agent | Merge evidence + validation checklist | No unresolved contradictions (or user resolved) |
| 5 | Main agent | Implementation strategy | Strategy cites merged evidence |
| 6 | Main agent | Atomic execution steps + probe templates | Every affected file has a step |
| 7 | Main agent | Verification / Definition of Done | DoD covers all major changes |
| 8 | Main agent | **Jira tracking & plan attachment** | Issue created/linked, draft confirmed, `.plan.md` attached |
| 9 | Main agent | Write `.plan.md`, present full plan, **`memory_store` NOW** | User can review in this chat with Jira link |

**Next in pipeline (after user approves):** `/pre-flight` → `/execute-plan` → `/codereview`

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work** (see `pipeline.md` Memory contract):

- query: technical plan, evidence, same workspace or feature area as the user request
- limit: 5

Present hits when similarity > 0.6. If none qualify, state that explicitly. Carry relevant hits into explorer prompts and the final plan's context section.

If `/architect-bootstrap` ran earlier in this session, load the situational awareness brief / canvas summary into Step 2. If bootstrap produced a requirements anchor (`docs/brainstorms/*-requirements.md` or brief §8), treat it as the primary input for §1 Problem & Goals — do not re-invent scope.

---

## Step 2: Exploration Design Brief

**Main agent only** — author this **before** dispatching explorers. Do not forward the raw user prompt as the exploration input.

Synthesize the user request, memory hits (Step 1), and your architectural read into a **Summarized Design Plan for Exploration**. Explorers use this brief to validate, refute, and enrich — not to infer intent from a one-liner.

### Required brief structure

```markdown
## Exploration Design Brief: {feature-slug}

### 1. Problem & Goals
- What problem are we solving? What does success look like?
- In scope / out of scope (explicit non-goals)

### 2. Constraints
- Technical, security, compatibility, or policy constraints
- Relevant memory hits or prior art (from Step 1)

### 3. Proposed Approach (pre-evidence)
- High-level strategy in 3–5 sentences — hypothesis, not fact
- Key design decisions still to validate

### 4. Suspected Impact
- Components, services, repos, directories likely touched
- Suspected files (initial hypothesis — explorers confirm or reject)
- Downstream consumers at risk

### 5. Open Questions for Explorers
- Numbered list of assumptions that MUST be verified in code
- e.g. "Does `FooService` already expose X?", "Is there an existing pattern for Y?"

### 6. Architecture Map (Mermaid)
- System context (`graph TD` or `sequenceDiagram`)
- Data flow: enter → through → exit
- Impact radius: downstream consumers highlighted

### 7. Exploration Success Criteria
- What evidence must explorers return before you can write atomic steps?
```

**Gate:** The brief must be complete (all 7 sections) before Step 3. You may show it in chat before dispatching.

---

## Step 3: Evidence-Gathering Exploration

**WAIT:** Do not start Step 4 until all dispatched explorers have returned.

Dispatch **3 explorers** in **one message** (parallel). Each row is fixed — never reuse the same `subagent_type` or model.

| Explorer | `subagent_type` | Model | Thinking | Cadence | Lens |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A — Deep trace** | `ce-repo-research-analyst` | `claude-4.6-opus-max-thinking` | Max | Slow, exhaustive | Repo structure, conventions, full-file reads, call chains, transitive consumers |
| **B — Reasoned scout** | `explore` | `gemini-3.1-pro` → `Cursor Grok 4.5` | High | Parallel breadth | Hypothesis-driven discovery, entrypoints, suspected-area sweep (`thoroughness: medium` or `very thorough`) |
| **C — Probe & correctness** | `ce-correctness-reviewer` | `Claude Sonnet 5` → `Cursor Grok 4.5` | Medium-high | Deliberate | Challenge assumptions, edge cases, contradictions; **read-only** probe checks (read tests/configs, dry commands — no writes) |

**Model policy:** Thinking-tier models only. Do NOT use `composer-2.5-fast`, `gpt-5.3-codex-high-fast`, or other speed-optimized models.

### Dispatch rules

1. One message, 3 Task calls, `readonly: true` on each.
2. Pass `model` explicitly (never `inherit` for explorers).
3. Per-explorer fallback (reasoning tier only, keep type + cadence):
   - A: `claude-4.6-opus-max-thinking` → `claude-sonnet-5-thinking-xhigh`
   - B: `gemini-3.1-pro` → `gpt-5.4-medium` → `composer-2.5`
   - C: `claude-sonnet-5-thinking-xhigh` → `gpt-5.4-medium` → `gemini-3.1-pro`
4. If only 2 reasoning models exist: dispatch **A + C** only; record missing explorer in the agreement matrix.
### Shared prompt payload (all explorers)

Attach the **full Exploration Design Brief** from Step 2 as the primary input. Do not substitute a shortened user prompt.

Each Task prompt MUST include:

1. **Exploration Design Brief** — entire document from Step 2 (all 7 sections)
2. **Mission statement** — one sentence: *"Validate, refute, and enrich this design brief with codebase evidence. Do not author the final plan."*
3. **Communication Contract** — strict telegraphic style (caveman), zero conversational filler or greetings, output structured evidence report directly
4. **Output contract** — return only the structured evidence report (format below); no plan authoring

Optional one-line user context is fine; the brief is the source of truth for exploration scope.

### Role-specific instructions (add to each prompt)

- **A:** Prioritize depth over breadth. Trace callers and transitive consumers. Read full files, not just signatures.
- **B:** Prioritize coverage. Validate or refute the hypothesis map. Find files A might miss.
- **C:** Prioritize falsification. List assumptions that could be wrong; cite read-only evidence (test files, configs, command output) that confirms or refutes them.

### Required evidence report format (explorer output)

Each explorer returns these sections:

#### 1. Affected Files
Per file: **Path** (absolute), **Evidence** (function/import/line), **`@ai-shebang` constraints** (quoted or summarized from header).

#### 2. Dependencies
External libs, internal modules, transitive consumers.

#### 3. Existing Patterns
Naming, error handling, logging/observability, testing.

#### 4. Unknowns & Contradictions
Missing files, ambiguous interfaces, conflicting patterns.

#### 5. Cynefin Pre-Classification
Per change area: Clear / Complicated / Complex + rationale.

---

## Step 4: Merge Exploration Evidence

**Main agent only** — merge the three reports:

| Merge rule | Rule |
| :--- | :--- |
| Affected files | UNION — any explorer listing a file keeps it |
| Dependencies | UNION all consumers |
| Patterns | Agreement = established; disagreement = flag |
| Unknowns | UNION all |
| Contradictions | Factual disagreements → **STOP**, present to user, wait for resolution |
| Cynefin | Take the **more complex** classification when explorers disagree |

### Evidence validation (required before Step 5)

- [ ] Every affected file was read by ≥1 explorer (not assumed)
- [ ] Every `@ai-shebang` header captured
- [ ] Every unknown listed explicitly
- [ ] No unresolved contradictions (or user chose how to resolve)

**Gate:** If contradictions remain unresolved, do not proceed to Steps 5–8.

### Explorer agreement matrix (produce here)

| Topic | A | B | C | Resolution |
| :--- | :--- | :--- | :--- | :--- |
| *(file, pattern, or assumption)* | agree / disagree / N/A | … | … | merged decision |

Include this matrix in the final plan (Step 8).

---

## Step 5: Implementation Strategy

Using merged evidence only:

1. **Pattern selection** — match existing codebase patterns (cite explorers).
2. **Breaking changes** — list consumers at risk with file evidence.
3. **Complexity per area** — merged Cynefin tags.

---

## Step 6: Atomic Execution Steps

Numbered steps. Each must be:

- **Isolated** — implementable and verifiable on its own where possible
- **Specific** — e.g. "Update `UserService.ts` to handle null email", not "Fix bug"
- **Evidence-linked** — cites file + `@ai-shebang` from Step 4
- **Cynefin-tagged** — Clear / Complicated / Complex
- **Verification-defined** — build, test, or lint command that proves done

**Complex steps** must include an inline probe template:

- Hypothesis, Method (safe-to-fail), Sensing, Acceptance criteria
- Mark: `**Cynefin: Complex -- probe required**` (see `plan-probes.mdc`)

**Gate:** Every file in the merged affected-files list must map to ≥1 step.

---

## Step 7: Verification & Test Specification (Definition of Done)

This section feeds **two consumers**: the executor (verification gates) and the **parallel test writer** agent in `/execute-plan`. Structure it so a test author can write tests from this section alone, without seeing the implementation.

### 7a. Test Specification Table

One row per testable behavior introduced or changed by the plan. The test writer agent uses this table as its primary input.

```markdown
| ID | Behavior Under Test | Module / Function / Endpoint | Input | Expected Output / Side Effect | Category |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T-1 | (what should happen) | (target from affected files) | (sample input or condition) | (assertion) | unit / integration / e2e |
| T-2 | (failure path) | ... | (invalid input or error condition) | (expected error / fallback) | unit |
| T-3 | (edge case) | ... | (boundary condition) | (expected behavior) | unit |
```

**Rules:**
- Minimum 3 rows per major change (success, failure, edge) — same as before, now structured
- **Module / Function / Endpoint** must reference affected files from Step 6 evidence — gives the test writer a target without seeing implementation
- **Category** determines test runner and isolation level
- For new APIs: include request/response shapes in the Expected column
- For refactors: include "behavior unchanged" regression rows

### 7b. Test Infrastructure Notes

- Existing test framework / runner (from explorer evidence)
- Test file naming convention and location pattern
- Mock/stub patterns already in use
- Any test fixtures or factories available

### 7c. Integration & Manual Checks

1. **Integration checks** — cross-service flows needing E2E verification
2. **Visual check** — manual UI/log verification

### 7d. Evidence Coverage Gate

- Confirm Step 6 covers all explored files
- Confirm every affected file maps to ≥1 test specification row

---

## Step 8: Jira Tracking & Plan Attachment

Verify Jira tracking and create/link the Jira issue upfront before plan presentation. Every technical plan originates with a real, tracked Jira issue.

### Procedure

1. **Ask the user:**

   > "Should I track this plan in Jira? Create a new issue under an epic, link to an existing issue, or skip?"
   >
   > Options:
   > - **Create new** — I'll draft a task/story under the appropriate epic
   > - **Update existing** — provide the issue key (e.g., PROJ-XXXX) and I'll link this plan
   > - **Skip** — no Jira tracking needed for this work

2. **If "Create new":**
   - Suggest parent epic: check `/architect-bootstrap` discovery or project epic hierarchy
   - Draft summary + description:
     - Summary: concise feature/bug description
     - Description: ADF or Markdown including Problem & Goals, Merged Evidence, Atomic Execution Steps, and Definition of Done
   - Discover required fields using project metadata before create
   - Present draft for user confirmation before creating
   - Create issue via Jira MCP or REST API (`POST /rest/api/3/issue`)
   - Capture created issue key (e.g. `PROJ-12345`)

3. **If "Update existing":**
   - Fetch the issue via MCP / API to confirm it matches
   - Add a comment with the plan overview and execution steps
   - Capture issue key

4. **If "Skip":**
   - Record `jira: null` in frontmatter; proceed to Step 9

5. **Attach Plan File to Jira Issue:**
   - Once the issue key is established and `.plan.md` is drafted, attach the plan file (`~/.cursor/plans/{feature-slug}.plan.md`) to the Jira issue via Jira REST API v3:
     ```bash
     curl -D- \
       -u "${JIRA_USERNAME}:${JIRA_API_TOKEN}" \
       -X POST \
       -H "X-Atlassian-Token: no-check" \
       -F "file=@${PLAN_FILE_PATH}" \
       "${JIRA_URL}/rest/api/3/issue/${ISSUE_KEY}/attachments"
     ```
     or script equivalent using multipart form-data.
   - Confirm attachment response status (200/201).

---

## Step 9: Write and Present the Plan

### 9a. Write file

Path: `~/.cursor/plans/{feature-slug}.plan.md` (`feature-slug` = kebab-case from the feature name).

YAML frontmatter — **include linked Jira issue** + **one todo per atomic step** from Step 6:

```yaml
---
name: feature-slug
overview: One-line summary
jira: PROJ-XXXX # or null if skipped
jira_url: https://jira.example.com/browse/PROJ-XXXX # or null
todos:
  - id: step-1
    content: "[Clear] Specific atomic step with verification"
    status: pending
  - id: step-2
    content: "[Complex] Step summary — probe required"
    status: pending
isProject: false
---
```

### 9b. Plan body (required sections)

1. Jira Issue Link & Attachment Status (e.g., `**Jira Issue:** [PROJ-XXXX](https://jira.example.com/browse/PROJ-XXXX) (plan attached)`)
2. Mermaid architecture diagram (from Step 2, updated if merge changed scope)
3. Merged evidence summary
4. Explorer agreement matrix (from Step 4)
5. Implementation strategy
6. Atomic execution steps (with probe templates for Complex)
7. Verification & Test Specification (from Step 7 — includes test spec table)

### 9c. Present and index (mandatory)

1. **Paste the full plan in this conversation** — not only on disk, not only in subagent output.
2. Call `memory_store` **NOW**: `title` = plan filename, `content` = **full plan file body**, `doc_type: plan`, `workspace` = current path.
3. End with: *"Plan written and attached to Jira issue {key}. Review the plan above. When approved, run `/pre-flight`."*

---

## Anti-Patterns

- Forwarding the raw user prompt to explorers instead of the Exploration Design Brief
- Starting Step 4 before all explorers finish
- Building on assumptions instead of explorer evidence
- Deferring Jira issue creation to `/eop` instead of creating/linking it with the plan
- Creating Jira issues without user approval
- Failing to attach `.plan.md` to the Jira issue
- One explorer, or same `subagent_type` / model twice
- Fast/non-thinking models for exploration or probe validation
- Skipping `@ai-shebang` reads
- Discarding a finding because only one explorer found it
- "Affected" files without evidence of why
- Vague atomic steps ("Fix bug", "Update module")
- Complex steps without probe templates
- Resolving contradictions silently without user visibility
- Leaving the deliverable only in subagent context or only as a file path
- Skipping `memory_search` or `memory_store`

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | **main agent** (+ explorer subagents in Step 3 only) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors) |
| 4 | `/execute-plan` | main agent (+ `execute-plan` executor) |
| 5 | `/codereview` | main agent (+ specialized review panel) |
