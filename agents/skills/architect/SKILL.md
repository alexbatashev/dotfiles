---
name: architect
description: "Design consequential interfaces, data structures, or module boundaries before implementation."
---

# Architect

Produce the design the user requested. A design-only request ends with the design. If implementation is included, continue through implementation and relevant verification unless the user requested a checkpoint.

Investigate the affected callers, data flow, and constraints. Reuse existing evidence. Use **how** when the mechanism is unclear and **why** when historical rationale would change the design. Delegate large exploration under the user's agent preferences.

Identify assumptions that could change the result. Inspect useful precedent or build a small probe when evidence can resolve an uncertainty. Ask the user about material preferences, especially in an interactive workflow. Continue independent work while waiting.

Write the caller's usage before deriving types, signatures, and module boundaries. Sketch only enough to make consequential choices reviewable. The sketch can be prose, pseudocode, or types. Do not introduce stub code merely to satisfy a phase.

Compare distinct alternatives when the choice is uncertain and consequential. Follow established patterns when they fit. Use [the rationale template](references/rationale-template.md) for a larger design and [the design checks](references/design-red-flags.md) when reviewing its shape.

When implementing, treat the sketch as a proposal informed by evidence. Record consequential discoveries and changes of approach. Revisit the design when the same workaround appears repeatedly, callers need internal knowledge, or types require repeated escape hatches. An isolated edge case does not by itself justify a rewrite.

Deliver the usage example, chosen shape, reasons for consequential choices, and unresolved questions that affect implementation. Scale the detail to the task. Keep mechanical steps brief.
