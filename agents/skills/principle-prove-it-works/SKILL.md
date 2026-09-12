---
name: principle-prove-it-works
description: "Verify a result with direct evidence appropriate to the changed behavior and its risk."
---

# Prove it works

Choose the observation that would establish the requested result. Inspect the changed artifact or exercise the affected behavior. A successful build establishes compilation, not runtime correctness.

Use existing tests and tools when they provide the needed evidence. Test an integration through its actual communication path when that path changed. A prose edit may need only a diff and a check of the rendered text.

Inspect delegated artifacts instead of relying only on summaries. When a check fails, investigate both the artifact and how it was observed.

Run required project checks. Repeat or broaden verification when relevant changes, failures, or unresolved risks justify it. Once the result is established, stop checking and deliver it. State material limits on what was verified.
