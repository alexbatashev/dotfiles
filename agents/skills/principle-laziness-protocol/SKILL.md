---
name: principle-laziness-protocol
description: "Prefer the smallest maintainable change when refactoring or considering an abstraction."
---

# Laziness protocol

Look for a simpler solution before adding code. Prefer deletion when it preserves required behavior.

Collapse wrappers and repeated coordination that add no useful boundary. Keep an abstraction when it hides meaningful complexity or owns a stable rule. File count alone does not establish that a design is too indirect.

Centralize repeated decisions and pass their results clearly. Before threading a signal through many layers, check whether ownership or the data model offers a more direct solution.

Optimize the change for the next reader and maintainer. Avoid speculative machinery and unrelated cleanup. Fewer lines are useful when they also reduce the work needed to understand the result.
