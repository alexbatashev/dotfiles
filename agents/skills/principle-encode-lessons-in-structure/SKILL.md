---
name: principle-encode-lessons-in-structure
description: "Enforce a demonstrated recurring rule with an appropriate check or shared implementation."
---

# Encode lessons in structure

When the same correction recurs, find its cause. Use a type, lint, runtime check, or shared implementation when it can enforce the rule reliably and belongs in the requested scope.

Choose the simplest effective mechanism. Test the behavior it protects, including legitimate cases that should remain allowed. Remove redundant instructions once the mechanism owns the rule.

Some decisions require judgment. Keep those instructions concise and add an example only when it clarifies a demonstrated failure. Do not generalize every isolated mistake into a permanent rule.

Record unrelated improvements in the user's side-quest list rather than pursuing them during the task or leaving them only in the conversation.
