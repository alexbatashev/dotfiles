---
name: principle-separate-before-serializing-shared-state
description: Separate independent writers or enforce ownership when concurrent work shares mutable state.
---

# Separate Before Serializing Shared State

When concurrent actors might share mutable state, first ask whether they truly need the same mutable object. If not, eliminate the sharing. When sharing is real, enforce serialization structurally: lockfiles, sequential phases, exclusive ownership. Instructions and conventions are not concurrency control.

**Why:** Concurrent writes to shared state create race conditions that are intermittent, hard to reproduce, and expensive to debug. Telling agents or goroutines to "take turns" does not work.

**Pattern:**
1. **Identify shared mutable state** (files both read and write, branches both push to, APIs both define and consume).
2. **Separate independent writers.** Decide whether the actors need one canonical object or are publishing independent facts. Give independent writers their own files, keys, branches, or state directories, and combine their results when reading or reporting. Two workers changing different fields in one `state.json` still share a write target. Separate state files avoid that sharing.
3. **Only when one shared write target is a real invariant, serialize access structurally** (lockfiles, sequential phases, single-writer actor, or atomic compare-and-swap). Treat "we need a lock" as a design smell to check, not as the default answer.
