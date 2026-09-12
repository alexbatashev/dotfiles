---
name: principle-redesign-from-first-principles
description: "Reconsider an existing design when a new requirement challenges its assumptions."
---

# Redesign from first principles

When a requirement conflicts with the current design's assumptions, ask what shape would fit if that requirement had been known from the start.

Inspect the affected callers and constraints. Compare that shape with a smaller change to the current design. Choose the simplest approach that satisfies the actual requirements and compatibility commitments.

A new requirement does not automatically justify a rewrite. When redesign is warranted, update the affected types, callers, tests, and documentation within the agreed scope. Deliver in coherent units and verify at useful boundaries.
