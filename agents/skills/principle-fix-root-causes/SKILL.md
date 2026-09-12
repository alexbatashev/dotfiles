---
name: principle-fix-root-causes
description: "Investigate the cause of a defect from reproduction, traces, or other direct evidence."
---

# Fix root causes

Identify intended behavior, observed behavior, and the smallest useful reproduction. If reproduction is unavailable, work from concrete traces or other evidence and state the limit on confidence.

Trace the failure to the violated assumption or invariant. Use instrumentation when evidence is missing. A defensive check is useful when it restores the actual contract, not when it merely hides a symptom.

Check for related instances when evidence suggests a shared defect. Fix those within the requested scope and record unrelated issues in the user's side-quest list.

For restart failures, inspect persisted state, configuration, caches, and ownership. Clearing state can establish a clue but is not itself a durable fix.

When repeated fixes fail, use **principle-attack-the-premise** to reconsider the assumption they share.
