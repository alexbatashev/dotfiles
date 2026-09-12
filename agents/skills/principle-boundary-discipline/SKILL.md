---
name: principle-boundary-discipline
description: "Place parsing and validation at trust boundaries and preserve established internal invariants."
---

# Boundary discipline

Parse external data into domain types at trust boundaries such as configuration, command input, storage, and network APIs. Handle invalid input there and propagate meaningful errors.

Trust established invariants inside the system. Avoid repeating checks that are already guaranteed. Validate internal state transitions when their correctness is not established by the types or earlier checks.

Keep domain rules separate from framework wiring when that makes them easier to understand and test. Prefer pure transformations where practical. Expose domain concepts through public interfaces instead of leaking transport or storage details.

A boundary is about trust and invariants, not only a module or process boundary. State which input is untrusted and what becomes guaranteed after parsing it.
