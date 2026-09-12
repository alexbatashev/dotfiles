---
name: how
description: "Explain runtime flow or assess code ownership and layering from source evidence. Use why for historical motivation."
---

# How

Explain the relevant runtime flow from actual code. For large exploration, follow the user's delegation and model preferences. Keep synthesis in the main session.

1. Scope the question to the entry point, types, and modules that matter. Reuse evidence already gathered in this conversation.
2. Search for relevant symbols and trace callers, callees, and data flow. Read targeted sections until you can follow the path from trigger to result.
3. Explain the mechanism plainly, citing files and symbols. Include ownership, important state, and surprising behavior when relevant. Match the length to the question.

For a critique, inspect the traced design against [the critique rubric](references/critique-rubric.md). Verify each concern in the code and distinguish actionable problems from preferences. Review in the main session unless the user requests independent reviewers.

For a larger explanation, [the explainer guide](references/explainer-prompt.md) provides optional structure. Keep explanation and synthesis in the main session, using bounded investigators when exploration needs delegation.
