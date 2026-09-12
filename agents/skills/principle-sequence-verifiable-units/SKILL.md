---
name: principle-sequence-verifiable-units
description: "Group a migration or edit sweep into coherent units with useful verification boundaries."
---

# Sequence work into verifiable units

Choose units that can be checked independently. A unit may be one behavior change or a batch of related mechanical edits. Verify it before building dependent work on it.

Capture a useful baseline. Preserve the user's branch and working changes. Rebase only when the task requires it.

For a planned migration, name the boundaries at which the system must work. Temporary breakage between those boundaries can be acceptable when scoped and reversible. Do not add compatibility code only to keep each individual edit green.

When committing is part of the workflow, order commits so reviewers can follow the change. A regression test and its fix can live in one commit. Failing-before evidence does not require a separate broken commit.
