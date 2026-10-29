---
name: create-plan
description: >-
  Stage 2 of the Antigravity agent pipeline. Dispatches evidence explorers to investigate
  the codebase and drafts an atomic, evidence-backed implementation plan (.plan.md) with
  Cynefin classifications, test specifications, and probe designs. Use when designing
  the implementation strategy ('how') before writing code.
---

# Technical Plan

**Invoke via:** `/create-plan`

**You are the coordinator.** Execute Steps 1–9 in order yourself. Main agent owns the deliverable — see [Agent Pipeline Contract](../agent-pipeline/SKILL.md).

The only subagents you may spawn are the **3 evidence explorers** in Step 3 (`readonly: true`). You merge their output and author the final plan in **this** conversation.

**Pipeline:** See [Agent Pipeline Contract](../agent-pipeline/SKILL.md). **Prior stage:** `/architect-bootstrap` (optional — carry Canvas brief into Step 2).

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

Call `memory_search` **before any other work**:

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

Dispatch **3 explorers** in parallel. Each row has a dedicated lens:

| Explorer | Role | Model | Lens |
| :--- | :--- | :--- | :--- |
| **A — Deep trace** | Deep Trace Explorer | `inherit` / `pro` | Repo structure, conventions, full-file reads, call chains, transitive consumers |
| **B — Reasoned scout** | Breadth Scout | `flash` | Hypothesis-driven discovery, entrypoints, suspected-area sweep |
| **C — Probe & correctness** | Correctness Lens | `inherit` / `pro` | Challenge assumptions, edge cases, contradictions; **read-only** probe checks |

`readonly: true` on each explorer.

### Shared prompt payload (all explorers)

Attach the **full Exploration Design Brief** from Step 2 as the primary input.

Each Task prompt MUST include:

1. **Exploration Design Brief** — entire document from Step 2 (all 7 sections)
2. **Mission statement** — *"Validate, refute, and enrich this design brief with codebase evidence. Do not author the final plan."*
3. **Communication Contract** — strict telegraphic style (caveman), zero conversational filler or greetings, output structured evidence report directly
4. **Output contract** — return only the structured evidence report (format below); no plan authoring

### Role-specific instructions

- **A:** Prioritize depth over breadth. Trace callers and transitive consumers. Read full files, not just signatures.
- **B:** Prioritize coverage. Validate or refute the hypothesis map. Find files A might miss.
- **C:** Prioritize falsification. List assumptions that could be wrong; cite read-only evidence (test files, configs, command output) that confirms or refutes them.

### Required evidence report format

Each explorer returns these sections:
1. **Affected Files:** Path, Evidence, `@ai-shebang` constraints
2. **Dependencies:** External libs, internal modules, transitive consumers
3. **Existing Patterns:** Naming, error handling, logging, testing
4. **Unknowns & Contradictions:** Missing files, ambiguous interfaces
5. **Cynefin Pre-Classification:** Clear / Complicated / Complex + rationale

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

### Explorer agreement matrix

| Topic | A | B | C | Resolution |
| :--- | :--- | :--- | :--- | :--- |
| *(file, pattern, or assumption)* | agree / disagree / N/A | … | … | merged decision |

---

## Step 5: Implementation Strategy

Using merged evidence only:
1. **Pattern selection** — match existing codebase patterns (cite explorers).
2. **Breaking changes** — list consumers at risk with file evidence.
3. **Complexity per area** — merged Cynefin tags.

---

## Step 6: Atomic Execution Steps

Numbered steps. Each must be:
- **Isolated** — implementable and verifiable on its own
- **Specific** — e.g. "Update `UserService.ts` to handle null email", not "Fix bug"
- **Evidence-linked** — cites file + `@ai-shebang` from Step 4
- **Cynefin-tagged** — Clear / Complicated / Complex
- **Verification-defined** — build, test, or lint command that proves done

**Complex steps** must include an inline probe template:
- Hypothesis, Method (safe-to-fail), Sensing, Acceptance criteria
- Mark: `**Cynefin: Complex -- probe required**`

---

## Step 7: Verification & Test Specification (Farley 4-Layer ATDD & Executable Specifications)

Prose specifications drift; specifications MUST be executable. Structure test specifications using Dave Farley's 4-layer acceptance test model to isolate domain intent from protocol/transport plumbing.

```
+-----------------------------------------------------------+
| Layer 1: Intent (Given / When / Then - Domain Language)   |
+-----------------------------------------------------------+
| Layer 2: Domain DSL (Language of the Problem Domain)      |
+-----------------------------------------------------------+
| Layer 3: Protocol Drivers (HTTP, CLI, gRPC, DB Adapters)  |
+-----------------------------------------------------------+
| Layer 4: System Under Test (SUT)                          |
+-----------------------------------------------------------+
```

### 7a. Executable Scenarios (4-Layer Acceptance Specifications)

```markdown
| ID | User / Domain Scenario (Intent) | DSL Operation (Domain Level) | Protocol Driver / Adapter | SUT Target | Category |
| :--- | :--- | :--- | :--- | :--- | :--- |
| T-1 | Given [state], When [action], Then [outcome] | dsl.doDomainAction(...) | HttpDriver / MemoryDriver | target module/endpoint | acceptance / unit |
| T-2 | Given [state], When [invalid action], Then [domain error] | dsl.doInvalidAction(...) | HttpDriver / MemoryDriver | target module/endpoint | acceptance / unit |
```

Rules for executable specifications:
- **Zero Protocol Leaks in Intent**: Layer 1 must contain ZERO HTTP codes, JSON payloads, or database column names. Express pure business intent.
- **Seam Isolation**: Protocol Drivers (Layer 3) isolate tests from infrastructure volatility so transport changes do not break test specifications.
- **Baseline Fitness Tests**: When deferring non-functional scaling (concurrency, caching, rate limiting), specify an automated fitness test to guard the boundary assumption.

### 7b. Test Infrastructure & Driver Notes
- Existing test framework / runner
- Test file and driver directory patterns (`test/dsl/`, `test/drivers/`)
- Mock/stub/test-double patterns already in use
- Test execution command: `npm test`, `pytest`, `go test ./...`

---

## Step 8: Jira Tracking & Plan Attachment

Verify Jira tracking if applicable. Create or link issue upfront before presenting plan. Attach the plan file to the issue if tracking is enabled.

---

## Step 9: Write and Present the Plan

### 9a. Write file

Path: `.plan.md` (or `.agents/plans/{feature-slug}.plan.md`).

YAML frontmatter:

```yaml
---
name: feature-slug
overview: One-line summary
jira: PROJ-XXXX # or null if skipped
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

### 9b. Present and index

1. **Paste the full plan in this conversation**.
2. Call `memory_store` **NOW**: `title` = plan filename, `content` = full plan body, `doc_type: plan`.
3. End with: *"Plan written. Review the plan above. When approved, run `/pre-flight`."*
