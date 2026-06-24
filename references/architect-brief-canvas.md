# Architect Brief Canvas Reference

Reference for `/architect-bootstrap` Step 6. **Not a subagent** — the main agent authors the canvas after readonly scanners return.

**Workflow:** `commands/architect-bootstrap.md` · **Pipeline:** `commands/pipeline.md`

---

## Canvas location

`~/.cursor/projects/<workspace>/canvases/architect-brief.canvas.tsx`

Resolve `<workspace>` from open workspace paths. List `~/.cursor/projects/` if unclear.

---

## Canvas rules

- Import ONLY from `cursor/canvas`. No npm packages, no Node built-ins, no relative imports.
- Default-export the top-level component.
- Embed ALL data inline. No `fetch()`, no network calls.
- Exactly one `.canvas.tsx` file. No helper files.
- Colors from `useHostTheme()` tokens only. No hardcoded hex.
- No gradients, no box-shadows, no emojis.
- Mix open sections with cards — do NOT wrap every section in Card.

Read `skills-cursor/canvas/SKILL.md` before authoring.

---

## Canvas structure

1. **Header row** — `H1` workspace name; `Grid` of `Stat` (file/service counts, **Agent Compatibility Score** when D–G ran).

2. **Intent & scope** — user intent; link to `docs/brainstorms/*-requirements.md` if present; `STRATEGY.md` one-liner.

3. **Situational Awareness** — `Table`:

| Aspect | Finding |
| :--- | :--- |
| **Tech Stack** | Languages, frameworks, runtimes |
| **Architecture Style** | Monolith / Microservices / Serverless / Hybrid |
| **Key Boundaries** | Ports & Adapters, API surfaces, event buses |
| **State Management** | Databases, caches, message queues |
| **CI/CD** | Tekton, GitHub Actions, GitLab CI, ArgoCD, etc. |
| **Messaging / Events** | Bus, broker, async patterns |
| **Gaps / Risks** | Tests, observability, coupling, tech debt |

4. **Key boundaries** — `Table`: Port/Adapter/API surface, type, layer.

5. **Gaps and risks** — `Table`: Priority, Finding, Why It Matters (include agent-compat top fixes when applicable).

6. **Platform Economics** (when platform repo) — Innovation, Cimarron, Railway/Guardrail verdicts.

7. **Jira discovery** (when Step 5 ran) — overlapping epics/tasks summary.

8. **Pipeline footer** — `bootstrap → create-plan → pre-flight → execute-plan → codereview`; note brainstorm doc handoff if any.

9. **Footer** — `Text` `tone="secondary"` `size="small"`: files directly validated.

### Pre-delivery self-check

- Visual hierarchy — one element stands out.
- Composition variety — not a wall of identical cards.
- No gradients, emojis, box-shadows, rainbow colors.

---

## Standing orders (post-bootstrap session)

### Cynefin-first triage

Classify every new request (Clear / Complicated / Complex / Chaotic). Cross-issue correlation: collapse symptoms that share one root cause.

### Architectural guardrails

Hexagonal boundaries, independent deployability, mechanisms not magic, abstractions not illusions, railways not guardrails, domain language over passthrough naming.

### Platform economics (when applicable)

Double Pyramid, Innovation, Cimarron, physical property honesty, stack-trace equivalent.

### Control-theory lens

Setpoint → process variable → error → minimal controller action.

### Incremental delivery

Small verifiable batches; define feedback after each change.

### Zero deferred debt

Debt found in review is fixed in the same change or explicitly de-scoped.

---

## Reject

- Chat-only brief with no canvas file.
- Subagents writing `.canvas.tsx` (main agent only).
- Full solutions without Cynefin classification.
- Code changes without reading `@ai-shebang` on touched files.
