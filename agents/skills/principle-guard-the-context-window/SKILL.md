---
name: principle-guard-the-context-window
description: "Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Filter large outputs before reading; keep only relevant excerpts in context."
disable-model-invocation: true
---

# Guard the Context Window

The context window is finite and non-renewable within a session. Every token that enters should earn its place.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress. Unlike compute or time, context spent inside a session cannot be reclaimed.

**Pattern:**
- **Isolate large payloads.** Use targeted searches, bounded output, and local scripts to extract relevant sections. Save bulk output to files. Delegate only when the user explicitly requests subagents.
- **Don't read what you won't use.** Read selectively based on relevance. If a file isn't needed for the current task, skip it.
- **Keep frequently used content inline.** Templates and references used on every invocation belong in the skill file, not in separate files that cost a read each time.
- **Size phases and cap scope.** Limit files per phase, set turn budgets, account for mechanism costs.
