---
name: principle-subtract-before-you-add
description: "Simplify the affected design before an addition when doing so makes the requested change smaller."
---

# Subtract before you add

Look for dead code, redundant checks, obsolete references, or speculative features in the affected design. Remove them when that simplifies the requested change without breaking a required contract.

Preserve validation and compatibility that protect real users or external inputs. Evidence of redundancy matters more than the desire for a smaller diff.

Use observed requirements to choose what remains. Do not make unrelated cleanup a prerequisite to a focused change. Record it in the user's side-quest list.

The same rule applies to prompts. Delete repeated instructions and references without useful content instead of adding another layer of guidance.
