---
name: principle-outcome-oriented-execution
description: "Complete a planned migration against its target behavior and explicit verification boundaries."
---

# Outcome-oriented execution

Work toward the intended end state. Avoid temporary compatibility code added only to keep every intermediate edit working.

Apply this to planned rewrites and migrations. State where intermediate breakage is acceptable and keep it scoped and reversible. Check coherent units before dependent work relies on them.

At completion, run the project's required checks and verify the affected runtime behavior. Choose checks for the migration's risks. Do not declare completion while a required behavior remains unverified.
