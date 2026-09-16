# Code Review

**Invoke via:** `/codereview`

**You are the coordinator.** Execute Steps 1–8 in order yourself. Main agent owns the deliverable — see `commands/pipeline.md`.

Spawn a **Review Panel** of specialized subagents in Step 5 (`readonly: true`). You merge findings and run verification gates in **this** conversation.

**Requires:** Staged or committed changes from `/execute-plan` (or user-provided diff scope).

**Pipeline:** See `commands/pipeline.md`. Plan-level gaps → update plan → `/pre-flight` (iterative).

## Execution checklist

| Step | Who | Action | Gate |
| :--- | :--- | :--- | :--- |
| 1 | Main agent | **`memory_search` NOW** | Hits shown |
| 2 | Main agent | Scan diff + `@ai-shebang` on touched files | Modified file list |
| 3 | Main agent | Build **Code Review Context Package** | Full plan + diff attached |
| 4 | Main agent | **Review Panel triage** + read applicable skills | Panel table published |
| 5 | Review panel (parallel) | Dispatch specialized reviewers | All returned |
| 6 | Main agent | Pessimistic merge + correlation | Unified report draft |
| 7 | Main agent | Verification gate (test, typecheck, build) | Pass or failures listed |
| 8 | Main agent | Write report, present in chat, **`memory_store` NOW** | User sees merged review |

**Next (if clean):** push + Jira Dev Complete per plan/issue.

---

## Step 1: Memory Recall (mandatory)

Call `memory_search` **before any other work** (see `pipeline.md`):

`query`: code review, plan slug, branch/feature · `limit: 5` · present hits > 0.6

---

## Step 2: Diff Scope

1. Identify all modified files (`git diff --staged` or user scope).
2. Read `@ai-shebang` on every touched file.
3. List consumers/callers of modified exports (initial pass).
4. Estimate diff size (lines changed) and domains touched (API, auth, DB, UI, platform, etc.).
5. **Security surface scan** — flag if diff touches: auth/authz, secrets/env, user input parsing, public endpoints, crypto/TLS, IAM/RBAC, SQL/command construction, file/path handling, dependency manifests (`package.json`, `go.mod`, `requirements.txt`), container/K8s security context, logging of sensitive data.

---

## Step 3: Code Review Context Package (by Reference)

**Main agent only.** Build the package by reference to avoid prompt token duplication across all panel members:

```markdown
## Code Review Context Package: {plan-slug}

### 1. Plan Identity
- Plan path (read via `view_file`), overview, workspace
- Pre-flight report path/summary if available

### 2. Execution Scope
- Which plan todos were implemented
- Commits or summary of changes

### 3. Diff Scope (by Reference)
- Git range: `git diff <base>...HEAD`
- Modified files (absolute paths) and line counts
- Hexagonal layer per file (Domain / Port / Adapter / Infrastructure)
*(Reviewers inspect diffs and files directly using native git / view_file tools)*

### 4. Consumer Map (initial)
- Callers/consumers from Step 2

### 5. Prior Art
- Memory hits from Step 1

### 6. Review Mission
Review changes against plan intent. System-wide impact, contracts, zero deferred debt. Do not rubber-stamp.
```

**Gate:** Sections 1–3 complete before Step 5.

---

## Step 4: Review Panel Triage

**Main agent only.** Select reviewers from the tables below. Publish the panel in chat before dispatching.

### Skills (read before Step 5 — inject criteria into reviewer prompts)

| Skill path | When to read | Attach checklist to |
| :--- | :--- | :--- |
| `skills/platform-design-review/SKILL.md` | APIs, IaC, platform abstractions, SDK/CLI surface | `codereview`, `ce-architecture-strategist` |
| Plugin: `component-structure-audit` | PatternFly component tree / composition changes | `pf-coding-standards` or `codereview` |
| Plugin: `pf-coding-standards` | PatternFly React imports / tokens | `ce-pattern-recognition-specialist` |
| Plugin: `pf-unit-test-standards` | PatternFly unit test changes | `ce-testing-reviewer` |

Read the skill file; paste the **relevant test/checklist section** into the matching reviewer Task prompt (not the whole skill).

### Core panel (always dispatch)

| ID | `subagent_type` | Model | Lens |
| :--- | :--- | :--- | :--- |
| **R1** | `codereview` | `claude-sonnet-5-thinking-xhigh` | Principal review — architecture, contracts, downstream impact (`agents/codereview.md`) |
| **R2** | `ce-correctness-reviewer` | `gemini-3.1-pro` | Logic, edge cases, state bugs |
| **R3** | `ce-maintainability-reviewer` | `gpt-5.4-medium` | Structure, coupling, naming, complexity |
| **R4** | `code-reviewer` | `claude-sonnet-5-thinking-xhigh` | **Plan alignment** — implementation vs plan todos & evidence (skip only if no plan) |
| **R5** | `ce-security-reviewer` | `claude-sonnet-5-thinking-xhigh` | **Exploitable diff security** — auth/authz, injection, input validation, IDOR, SSRF, path traversal in changed code |
| **R6** | `ce-security-sentinel` | `gemini-3.1-pro` | **Security audit** — secrets/credentials in diff, OWASP patterns, unsafe crypto, dependency CVE surface, sensitive data in logs |

**Security core is mandatory** for every `/codereview` after `/execute-plan`. Only skip R5+R6 if the diff is **docs-only** (markdown, comments, no executable/config-IaC changes) — state that explicitly in the triage table.

### Conditional panel (dispatch when signal matches)

| ID | `subagent_type` | Model | Trigger |
| :--- | :--- | :--- | :--- |
| **C1** | `ce-testing-reviewer` | `gpt-5.4-medium` | **Mandatory after `/execute-plan`** (TDD gate). Also triggers on: tests changed or production logic without test updates |
| **C2** | `ce-api-contract-reviewer` | `gemini-3.1-pro` | API routes, types, serialization, exported signatures |
| **C4** | `ce-reliability-reviewer` | `Claude Sonnet 5` | Retries, timeouts, jobs, error handling, async handlers |
| **C5** | `ce-performance-reviewer` | `gemini-3.1-pro` | Queries, loops, caching, I/O-heavy paths |
| **C6** | `ce-adversarial-reviewer` | `claude-sonnet-5-thinking-xhigh` | Diff ≥ 50 lines OR auth/payments/data-mutation paths |
| **C7** | `ce-data-integrity-guardian` | `Claude Sonnet 5` | Migrations, models, persistent data constraints |
| **C8** | `ce-data-migration-reviewer` | `gpt-5.4-medium` | Migration files, schema dumps, backfills |
| **C9** | `ce-julik-frontend-races-reviewer` | `gemini-3.1-pro` | Async UI, Stimulus/Turbo, DOM timing |
| **C10** | `ce-swift-ios-reviewer` | `Claude Sonnet 5` | Swift, SwiftUI, iOS project files |
| **C11** | `ce-architecture-strategist` | `claude-sonnet-5-thinking-xhigh` | New services, large refactors, cross-boundary changes |
| **C12** | `ce-project-standards-reviewer` | `gpt-5.4-medium` | Any change — project `AGENTS.md` / conventions |
| **C13** | `ce-pattern-recognition-specialist` | `gemini-3.1-pro` | New abstractions or inconsistent patterns suspected |
| **C14** | `component-structure-audit` | `Claude Sonnet 5` | PatternFly layout / hierarchy changes |
| **C15** | `pf-coding-standards` | `gpt-5.4-medium` | PatternFly React code |
| **C16** | `pf-unit-test-standards` | `gpt-5.4-medium` | PatternFly RTL tests |

**Panel limits:** Dispatch **all core** (R1–R6 minus R4 if no plan; minus R5+R6 only for docs-only diffs) **plus** matching conditional reviewers in **one message**. Cap at **12 parallel** — if more match, prioritize: **R5/R6** (never drop) → C6 → C2 → C7/C8 → C1 → remaining.

**Security merge rule:** Any **HIGH** security finding from R5, R6, or C6 → overall risk **cannot** be Low; blocks push until fixed or explicitly accepted by user.

**Model policy:** Thinking-tier only. No `*-fast` models.

---

## Step 5: Parallel Reviews

**WAIT** for all panel members before Step 6.

One message, one Task per panel member, `readonly: true`.

### Each Task prompt MUST include

1. **Code Review Context Package by Reference** (pass plan path, git diff range, and modified paths; do NOT dump full file contents)
2. **Communication Contract:** strict telegraphic style (caveman), zero conversational filler or greetings, output structured findings directly
3. **Reviewer role** — ID + lens from triage table
4. **Skill addendum** — pasted checklist from Step 4 (if applicable)
5. **TDD context (C1 only):** Include the plan's Step 7 Test Specification table + the reconciliation summary from `/execute-plan` outcome. C1 validates: (a) every spec row has a corresponding test, (b) tests assert on public interface not implementation details, (c) divergences noted in reconciliation are resolved or justified.
6. **Mission:** return structured findings only (Summary, Downstream Impact, Findings table, Verification suggestions) — use `agents/codereview.md` output format as baseline
7. **Flagged By:** reviewer must sign findings with their ID (R1, R5, C6, …)

---

## Step 6: Merge (Pessimistic)

| Rule | Policy |
| :--- | :--- |
| Risk level | **Highest** across reviewers |
| Cynefin | **More complex** wins |
| Findings | **Union** all — tag with reviewer ID |
| Severity (same issue) | **Highest** wins |
| Downstream impact | **Union** consumers |
| Contradictions | Flag for user |
| Security findings | Union R5 + R6; **any exploitable issue = HIGH** unless proven false positive with evidence |

**Cross-issue correlation:** Collapse shared root-cause findings.

**Security section (required in report):** Dedicated table — Finding, OWASP/category, Severity, File, Fix, Flagged By (R5/R6/…).

**Reviewer agreement matrix:**

| Topic | R1 | R2 | … | Resolution |
| :--- | :--- | :--- | :--- | :--- |

---

## Step 7: Verification Gate

| Check | Command | Result |
| :--- | :--- | :--- |
| Unit tests | project test command | pass/fail |
| Typecheck | tsc/mypy/etc. | pass/fail |
| Build | npm run build / equivalent | pass/fail |
| **Test spec coverage** | Compare test files vs plan Step 7a table | all spec rows covered / gaps listed |
| **TDD divergence** | Review reconciliation summary from `/execute-plan` | resolved / unresolved items |

Do NOT approve push if any check fails. Unresolved TDD divergences (test writer targeted a different interface than the executor implemented) must be resolved or explicitly accepted — they indicate plan ambiguity that should be documented.

---

## Step 8: Write, Present, Index

Path: `~/.cursor/plans/{plan-slug}-Code_Review_YYYY-MM-DD_HHMM.md`

Sections: Summary (panel list + models), Downstream Impact, Findings & Fixes (with **Flagged By** column), Reviewer Disagreements, Verification Plan, Verification Gate table.

1. **Paste full report in this conversation.**
2. Call `memory_store` **NOW**: full report body, `doc_type: codereview`.
3. If clean: offer Jira Dev Complete (discover transition ID — never hardcode).

---

## Anti-Patterns

- Only `codereview` × 3 with same lens (use specialized panel)
- Reviewers without full plan + diff context
- Lowest severity wins
- Skipping triage (always document which reviewers ran and why)
- >10 parallel reviewers without prioritization
- Skipping `memory_search` or `memory_store`

## Pipeline position

| # | Command | Actor |
| :--- | :--- | :--- |
| 1 | `/architect-bootstrap` | main agent (+ scan panel) |
| 2 | `/create-plan` | main agent (+ evidence explorers) |
| 3 | `/pre-flight` | main agent (+ `pre-flight` auditors) |
| 4 | `/execute-plan` | main agent (+ executor) |
| 5 | `/codereview` | **main agent** (+ specialized review panel) |
