---
name: principle-foundational-thinking
description: "Choose data structures and shared foundations for the access patterns the task requires."
---

# Foundational thinking

Understand the data, invariants, and access patterns before adding logic around them. Choose a representation that makes the required operations clear and invalid states difficult to construct.

Share types and domain rules when callers need the same contract. Similar lines alone do not justify an abstraction.

Before sharing mutable state, identify who can change it and what concurrent changes mean. Separate ownership when the actors do not need one shared object.

Build foundations early when the planned work depends on them. Reuse existing infrastructure. Do not add CI, a framework, or test infrastructure merely because it could help hypothetical future work.

Remove unnecessary complexity in the affected design when that makes the requested change smaller. Record unrelated cleanup for later.
