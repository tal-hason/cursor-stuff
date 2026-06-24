# Cursor Agent Pipeline

A complete agent pipeline for [Cursor IDE](https://cursor.com) that turns a vague idea into reviewed, committed code through six structured stages.

```
/architect-bootstrap  →  /create-plan  →  /pre-flight  →  /execute-plan  →  /codereview  →  /eop
     (WHERE + WHAT)        (HOW)           (audit)         (build)          (review)       (close)
```

## What's in this repo

This is a `.cursor` configuration package. Copy its contents into your `~/.cursor/` directory (or a project-level `.cursor/` folder) to get the full pipeline.

```
cursor-public/
├── AGENTS.md                              # Pipeline memory (continual learning)
├── commands/                              # 10 slash commands
│   ├── pipeline.md                        # Canonical pipeline contract
│   ├── architect-bootstrap.md             # Step 1: workspace scan + canvas brief
│   ├── create-plan.md                     # Step 2: evidence-backed plan
│   ├── pre-flight.md                      # Step 3: confidence audit (iterative)
│   ├── execute-plan.md                    # Step 4: implement plan
│   ├── codereview.md                      # Step 5: multi-reviewer panel
│   ├── eop.md                             # Step 6: session digest + learnings
│   ├── uiux-expert.md                     # Standalone: UI/UX design orchestrator
│   ├── generate-shebangs.md               # Standalone: AI Shebang header generator
│   └── schedule-task.md                   # Standalone: task scheduler
├── agents/                                # 7 worker subagent definitions
│   ├── codereview.md                      # Principal code reviewer (R1)
│   ├── pre-flight.md                      # Cynefin confidence auditor
│   ├── execute-plan.md                    # Plan executor
│   ├── probe-runner.md                    # Safe-to-fail experiment runner
│   ├── uiux-expert.md                     # UI/UX design orchestrator
│   ├── generate-shebangs.md               # AI Shebang generator
│   └── schedule-task.md                   # Task scheduler
├── references/
│   └── architect-brief-canvas.md          # Canvas structure for bootstrap
├── docs/
│   └── pipeline-howto.md                  # Team onboarding guide
├── rules/                                 # 12 always-on rules (.mdc)
│   ├── persona.md                         # Systems Architect persona
│   ├── cynefin.mdc                        # Cynefin sense-making framework
│   ├── kiss.mdc                           # KISS problem-solving principle
│   ├── ai-shebang.mdc                     # @ai-rules header enforcement
│   ├── ai-rules.mdc                       # Prompt engineering standards
│   ├── codebase-workflow.mdc              # Code conventions + context gathering
│   ├── refactor.mdc                       # Pre-refactor documentation
│   ├── microservices.mdc                  # Distributed systems patterns
│   ├── platform-strategy.mdc             # Platform design principles (7 C's)
│   ├── platform-economics.mdc             # Double Pyramid economics model
│   ├── platform-abstraction-quality.mdc   # Abstraction vs illusion discipline
│   └── plan-probes.mdc                    # Complex step probe templates
├── skills/                                # 3 reusable agent skills
│   ├── probe-before-assume/SKILL.md       # Evidence-first behavior
│   ├── cynefin-sense-making/SKILL.md      # Domain classification
│   └── platform-design-review/SKILL.md    # Platform review (6 tests + 7 C's)
├── hooks.json                             # Session hooks configuration
└── hooks/
    └── codereview-reminder.sh             # Remind to run /codereview
```

## Installation

### Full pipeline (recommended)

Copy the entire package into your Cursor user config:

```bash
cp -r cursor-public/* ~/.cursor/
```

### Project-level

Copy into a project's `.cursor/` folder for repo-scoped pipeline:

```bash
cp -r cursor-public/* /path/to/project/.cursor/
```

### Cherry-pick

Copy individual files. At minimum, the pipeline needs:
- `commands/pipeline.md` + the 6 pipeline commands
- `agents/` (worker definitions)
- `rules/cynefin.mdc` + `rules/persona.mdc` (core behavior)

## How the pipeline works

See [`docs/pipeline-howto.md`](docs/pipeline-howto.md) for the full team guide.

### Quick start

```
/architect-bootstrap ~/Git/my-project

Add a health check endpoint that returns pod readiness and database connectivity
```

The agent scans the workspace, builds a canvas with situational awareness, then prompts you to continue:

```
/create-plan        # Build atomic implementation plan
/pre-flight         # Audit plan confidence (iterative — run again anytime)
/execute-plan       # Implement step by step
/codereview         # Multi-reviewer panel
/eop                # Capture learnings, compress context
```

### Recommended: Two-session workflow

1. **Session 1 (explore):** Run `/architect-bootstrap` to scan and understand the workspace. Brainstorm with the agent. Ask it to write a focused feature prompt.
2. **Session 2 (execute):** Open a fresh chat. Paste the feature prompt into `/architect-bootstrap`. Run the full pipeline with clean context.

Plans and canvases from Session 1 persist on disk for Session 2 to pick up.

## Design principles

This pipeline is built on:

- **[Cynefin framework](https://en.wikipedia.org/wiki/Cynefin_framework)** — classify problems before solving them (Clear/Complicated/Complex/Chaotic)
- **[Control theory](https://en.wikipedia.org/wiki/Control_theory)** — user intent = setpoint, code = controller, tests/logs = feedback loop
- **[Hexagonal architecture](https://alistair.cockburn.us/hexagonal-architecture/)** — ports & adapters, domain independence
- **[Continuous delivery](https://continuousdelivery.com/)** — small verifiable batches, build quality in
- **[Platform Strategy](https://architectelevator.com/book/platformstrategy/)** (Gregor Hohpe) — 7 C's, Double Pyramid, abstractions not illusions
- **Probe-before-assume** — never act on assumptions when evidence is available

## Excluded from this package

This is a sanitized extract. Internal/company-specific items not included:

- Jira workflow rules (instance URLs, custom field IDs, team accounts)
- GitLab internal rules (host aliases, repo group mappings)
- OCP cluster login aliases
- Bot MR description protocols
- Company-specific skills (Jira integration, build audits)
- MCP server credentials (`mcp.json`)
- Session hook for git config sync
- `plans/` directory (generated artifacts)
- `skills-cursor/` (Cursor-managed, auto-synced by the IDE)

## License

MIT
