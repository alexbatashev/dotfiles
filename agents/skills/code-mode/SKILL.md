---
name: code-mode
description: "Implement a requested feature, bug fix, or code change using the project's conventions."
---

# Code mode

Finish the requested behavior with the smallest adequate change. Follow the surrounding code style and preserve existing contracts unless the task changes them. Do not add unrelated cleanup or speculative abstractions.

Write comments for a non-obvious reason or constraint, plus public API documentation. Keep them accurate and avoid narrating what the code already says. Do not add yourself as a commit co-author. Keep private session details out of code, commits, and PR descriptions.

Read the code and references needed to understand the affected path. Use a checklist when it helps track the work. Do not load a catalog of principles or require a fixed sequence for every task.

Apply specialist guidance when it changes a decision:

- Use **how** when runtime flow or ownership is unclear, and **why** when historical rationale matters.
- Use **architect** when a consequential interface or module decision needs a design. A routine function edit does not need a design workflow.
- Use **planning** when creating or following a plan. Use **show-me-your-work** when consequential decisions need a durable record.
- Use **unslop** for writing and **technical-writing** for document-specific guidance.

Inspect facts or run a small experiment before asking the user to resolve something observable. Ask about material product choices and preferences. Follow an explicitly requested interactive workflow. If evidence invalidates the proposed method, explain the finding and revise the method while preserving the intended outcome.

Use the user's delegation policy for large exploration. Choose models from their preference table, give agents bounded tasks, and keep synthesis in the main session.

Verify the changed behavior with relevant existing checks. Add a regression test when it offers useful coverage at a reasonable cost. Repeat checks after relevant changes or failures, then deliver the result with the evidence and any material limits.

Honor existing authorization. Prepare a concrete result before asking about an additional external action. Record unrelated side quests under the user's logging policy and return to the requested work.
