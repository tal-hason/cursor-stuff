# Generate AI Shebangs

**Trigger:** `/shebang`

**Instructions:**
1. Look at the currently open file (or the files specified by the user).
2. Analyze the code to understand its specific responsibilities, edge cases, and architectural patterns.
3. Generate a concise but strict "AI Shebang" (block comment) at the top of the file using the format: `// @ai-rules: ...`
4. If a header already exists, strictly review it. Remove outdated rules and add new ones based on the current code logic.
5. Do not modify the actual code logic, only the comment header.
