# Technical Plan

**Invoke via:** `/create-plan`

**You are the coordinator.** Execute Steps 1–8 in order yourself. Main agent owns the deliverable — see `commands/pipeline.md`.

The only subagents you may spawn are the **3 evidence explorers** in Step 3 (`readonly: true`). You merge their output and author the final plan in **this** conversation.

**Pipeline:** See `commands/pipeline.md`. **Prior stage:** `/architect-bootstrap` (optional — carry Canvas brief into Step 2).

## Execution checklist

| Step | Who | Action | Gate before next step |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | Write **Exploration Design Brief** + Mermaid map | Brief complete — ready to attach to explorer prompts |
| 2 | 3 explorers (parallel) | Dispatch A, B, C via Task tool | **All 3 completed** (or A+C if 2-model fallback) |
| 3 | Main agent | Merge evidence + validation checklist | No unresolved contradictions (or user resolved) |
| 4 | Main agent | Implementation strategy | Strategy cites merged evidence |
| 5 | Main agent | Atomic execution steps + probe templates | Every affected file has a step |
| 6 | Main agent | Verification / Definition of Done | DoD covers all major changes |
| 7 | Main agent | Write `.plan.md`, present full plan | User can review in this chat |

**Next in pipeline (after user approves):** `/pre-flight` → `/execute-plan` → `/codereview`

If `/architect-bootstrap` ran earlier in this session, load the situational awareness brief / canvas summary into Step 1. If bootstrap produced a requirements anchor (`docs/brainstorms/*-requirements.md` or brief §8), treat it as the primary input for §1 Problem & Goals — do not re-invent scope.

---

## Step 1: Exploration Design Brief

**Main agent only** — author this **before** dispatching explorers. Do not forward the raw user prompt as the exploration input.

Synthesize the user request and your architectural read into a **Summarized Design Plan for Exploration**. Explorers use this brief to validate, refute, and enrich — not to infer intent from a one-liner.

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

## Step 2: Evidence-Gathering Exploration

**WAIT:** Do not start Step 3 until all dispatched explorers have returned.

Dispatch **3 explorers** in **one message** (parallel). Each row is fixed — never reuse the same `subagent_type` or model.

| Explorer | `subagent_type` | Model | Thinking | Cadence | Lens |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A — Deep trace** | `ce-repo-research-analyst` | `claude-4.6-opus-max-thinking` | Max | Slow, exhaustive | Repo structure, conventions, full-file reads, call chains, transitive consumers |
| **B — Reasoned scout** | `explore` | `gemini-3.1-pro` | High | Parallel breadth | Hypothesis-driven discovery, entrypoints, suspected-area sweep (`thoroughness: medium` or `very thorough`) |
| **C — Probe & correctness** | `ce-correctness-reviewer` | `gpt-5.4-medium` | Medium-high | Deliberate | Challenge assumptions, edge cases, contradictions; **read-only** probe checks (read tests/configs, dry commands — no writes) |

**Model policy:** Thinking-tier models only. Do NOT use `composer-2.5-fast`, `gpt-5.3-codex-high-fast`, or other speed-optimized models.

### Dispatch rules

1. One message, 3 Task calls, `readonly: true` on each.
2. Pass `model` explicitly (never `inherit` for explorers).
3. Per-explorer fallback (reasoning tier only, keep type + cadence):
   - A: `claude-4.6-opus-max-thinking` → `claude-4.6-sonnet-medium-thinking`
   - B: `gemini-3.1-pro` → `gpt-5.4-medium` → `composer-2.5`
   - C: `gpt-5.4-medium` → `claude-4.6-sonnet-medium-thinking` → `gemini-3.1-pro`
4. If only 2 reasoning models exist: dispatch **A + C** only; record missing explorer in the agreement matrix.
### Shared prompt payload (all explorers)

Attach the **full Exploration Design Brief** from Step 1 as the primary input. Do not substitute a shortened user prompt.

Each Task prompt MUST include:

1. **Exploration Design Brief** — entire document from Step 1 (all 7 sections)
2. **Mission statement** — one sentence: *"Validate, refute, and enrich this design brief with codebase evidence. Do not author the final plan."*
3. **Output contract** — return only the structured evidence report (format below); no plan authoring

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

## Step 3: Merge Exploration Evidence

**Main agent only** — merge the three reports:

| Merge rule | Rule |
| :--- | :--- |
| Affected files | UNION — any explorer listing a file keeps it |
| Dependencies | UNION all consumers |
| Patterns | Agreement = established; disagreement = flag |
| Unknowns | UNION all |
| Contradictions | Factual disagreements → **STOP**, present to user, wait for resolution |
| Cynefin | Take the **more complex** classification when explorers disagree |

### Evidence validation (required before Step 4)

- [ ] Every affected file was read by ≥1 explorer (not assumed)
- [ ] Every `@ai-shebang` header captured
- [ ] Every unknown listed explicitly
- [ ] No unresolved contradictions (or user chose how to resolve)

**Gate:** If contradictions remain unresolved, do not proceed to Steps 4–7.

### Explorer agreement matrix (produce here)

| Topic | A | B | C | Resolution |
| :--- | :--- | :--- | :--- | :--- |
| *(file, pattern, or assumption)* | agree / disagree / N/A | … | … | merged decision |

Include this matrix in the final plan (Step 7).

---

## Step 4: Implementation Strategy

Using merged evidence only:

1. **Pattern selection** — match existing codebase patterns (cite explorers).
2. **Breaking changes** — list consumers at risk with file evidence.
3. **Complexity per area** — merged Cynefin tags.

---

## Step 5: Atomic Execution Steps

Numbered steps. Each must be:

- **Isolated** — implementable and verifiable on its own where possible
- **Specific** — e.g. "Update `UserService.ts` to handle null email", not "Fix bug"
- **Evidence-linked** — cites file + `@ai-shebang` from Step 3
- **Cynefin-tagged** — Clear / Complicated / Complex
- **Verification-defined** — build, test, or lint command that proves done

**Complex steps** must include an inline probe template:

- Hypothesis, Method (safe-to-fail), Sensing, Acceptance criteria
- Mark: `**Cynefin: Complex -- probe required**` (see `plan-probes.mdc`)

**Gate:** Every file in the merged affected-files list must map to ≥1 step.

---

## Step 6: Verification (Definition of Done)

1. **Test cases** — 3 per major change (success, failure, edge)
2. **Integration checks** — cross-service flows needing E2E verification
3. **Visual check** — manual UI/log verification
4. **Evidence coverage** — confirm Step 5 covers all explored files

---

## Step 7: Write and Present the Plan

### 7a. Write file

Path: `~/.cursor/plans/{feature-slug}.plan.md` (`feature-slug` = kebab-case from the feature name).

YAML frontmatter — **one todo per atomic step** from Step 5:

```yaml
---
name: feature-slug
overview: One-line summary
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

### 7b. Plan body (required sections)

1. Mermaid architecture diagram (from Step 1, updated if merge changed scope)
2. Merged evidence summary
3. Explorer agreement matrix (from Step 3)
4. Implementation strategy
5. Atomic execution steps (with probe templates for Complex)
6. Verification plan (from Step 6)

### 7c. Present in chat

1. **Paste the full plan in this conversation** — not only on disk, not only in subagent output.
2. End with: *"Review the plan above. When approved, run `/pre-flight`."*

---

## Anti-Patterns

- Forwarding the raw user prompt to explorers instead of the Exploration Design Brief
- Starting Step 4 before all explorers finish
- Building on assumptions instead of explorer evidence
- One explorer, or same `subagent_type` / model twice
- Fast/non-thinking models for exploration
- Skipping `@ai-shebang` reads
- Discarding a finding because only one explorer found it
- "Affected" files without evidence of why
- Vague atomic steps ("Fix bug", "Update module")
- Complex steps without probe templates
- Resolving contradictions silently without user visibility
- Leaving the deliverable only in subagent context or only as a file path

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | **main agent** (+ explorer subagents in Step 3 only) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors) |
| 4 | `/execute-plan` | main agent (+ `execute-plan` executor) |
| 5 | `/codereview` | main agent (+ specialized review panel) |
