# General rules

- Keep replies concise and easy to read. Use `/unslop` skill always - no exceptions.
- Record unrelated side quests in `~/project-plans/<project>/side-quests.tsv`. Include the proposed work, why it matters, where it was found, and status. Check for an existing entry before adding one. Do not pursue it unless the user brings it into scope.
- Keep consequential decision notes in `~/project-plans/<project>/_trails/<date>-<task>.tsv`. Use the **show-me-your-work** skill for the shared format and helper. The main agent owns shared logs. Subagents return discoveries for the main agent to record.
- I will be a harsh judge of your work. If your next reply is going to need an apology, stop and re-consider it. Change your behavior in a way that would not require me to intervene.
- If running a review of the work and `~/project-plans/<project>/feedback.tsv` exists, use it to also verify that the work meets past feedback rules.

# Subagent usage

- Use subagents to protect the main session's context during large exploration, or when explicitly requested. Handle small tasks in the main session.
- Start subagents with fresh context. Give each one a bounded task, the necessary facts and artifact paths, a stopping condition, and the expected result. Do not inherit or copy the conversation history, even when using the same model. In Codex, use `fork_turns: "none"`.
- Treat subagents as disposable workers. Keep requirements, decisions, and final synthesis in the main session. Have agents return concise findings, evidence or artifact paths, and blockers. Keep their raw tool output and working notes out of the main thread.
- Run at most 3 subagents at a time across the task, including nested agents. Close completed agents and start fresh ones as work progresses. Ask before exceeding the concurrent limit.

# Coding principles - non-negotiable

Finish the requested behavior with the smallest adequate change. Follow the surrounding code style and preserve existing contracts unless the task changes them. Do not add unrelated cleanup or speculative abstractions.

Write comments for a non-obvious reason or constraint, plus public API documentation. Keep them accurate and avoid narrating what the code already says. Do not add yourself as a commit co-author. Keep private session details out of code, commits, and PR descriptions.

Code is written to be read by humans. If the code you just wrote requires a comment or documentation in prose explaining how it works, stop and re-write the code so that humans can understand it.

Apply specialist guidance when it changes a decision:

- Use **how** when runtime flow or ownership is unclear, and **why** when historical rationale matters.
- Use **architect** when a consequential interface or module decision needs a design. A routine function edit does not need a design workflow.
- Use **planning** when creating or following a plan. Use **show-me-your-work** when consequential decisions need a durable record.
- Use **unslop** for writing and **technical-writing** for document-specific guidance.

Inspect facts or run a small experiment before asking the user to resolve something observable. Ask about material product choices and preferences. Follow an explicitly requested interactive workflow. If evidence invalidates the proposed method, explain the finding and revise the method while preserving the intended outcome.
