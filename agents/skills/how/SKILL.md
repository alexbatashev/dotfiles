---
name: how
description: "Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). Explains subsystem architecture, runtime flow, onboarding mental models. Can critique architecture. Use why for motivation."
---

# How

Explain the relevant runtime flow from actual code in the main session. Use subagents only when the user explicitly requests them.

1. Scope the question to the entry point, types, and modules that matter. Reuse evidence already gathered in this conversation.
2. Search for relevant symbols and trace callers, callees, and data flow. Read targeted sections until you can follow the path from trigger to result.
3. Explain the mechanism plainly, citing files and symbols. Include ownership, important state, and surprising behavior when relevant. Match the length to the question.

For a critique, inspect the traced design against [the critique rubric](references/critique-rubric.md). Verify each concern in the code and distinguish actionable problems from preferences. Review in the main session unless the user requests independent reviewers.

For a larger explanation, [the explainer guide](references/explainer-prompt.md) provides optional structure. Do not create separate explorer, explainer, or critic agents by default.
