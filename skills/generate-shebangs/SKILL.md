---
name: generate-shebangs
description: >-
  Analyzes source code files and generates or updates concise, strict @ai-rules shebang
  header comments at the top of files without altering code logic. Use to embed file-level
  constraints and architectural boundaries.
---

# Generate AI Shebangs

**Invoke via:** `/generate-shebangs` (or `/shebang`)

Analyzes target code files and maintains strict, context-preserving `@ai-rules` headers.

## Instructions

1. Look at the target file(s) specified by the user or identified in the plan/diff.
2. Analyze the code to understand its specific responsibilities, edge cases, and architectural patterns.
3. Generate a concise but strict "AI Shebang" (block comment) at the top of the file using the format:
   ```typescript
   // @ai-rules: [domain invariants, critical constraints, anti-patterns to avoid]
   ```
4. If a header already exists, strictly review it:
   - Remove outdated rules no longer relevant to the implementation.
   - Add new constraints based on the current code logic.
5. **Do not modify the actual code logic**, only the comment header.
