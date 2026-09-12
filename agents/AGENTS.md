# General preferences

- Keep replies concise and easy to read.
- Use `/unslop` skill always - no exceptions.
- Use judgment about process. Read and check what the task needs, then finish the requested work.
- Let skills activate when they fit the task. Skill selection does not expand what the user authorized.
- Record unrelated side quests in `~/project-plans/<project>/side-quests.tsv`. Include the proposed work, why it matters, where it was found, and status. Check for an existing entry before adding one. Do not pursue it unless the user brings it into scope.
- Keep consequential decision notes in `~/project-plans/<project>/_trails/<date>-<task>.tsv`. Use the **show-me-your-work** skill for the shared format and helper. The main agent owns shared logs. Subagents return discoveries for the main agent to record.

## Subagents preference

Use table below when choosing a model for a subagent:

| Model            | Code taste | Price | Reasoning | Comments                                                                               |
|------------------|------------|-------|-----------|----------------------------------------------------------------------------------------|
| Claude Fable 5.1 | 7/10       | 3/10  | 8/10      | Great for complex architecture tasks.                                                  |
| Claude Opus 5    | 5/10       | 5/10  | 5/10      | Good for general coding tasks. Never use for code review or architecture.              |
| Claude Sonnet 5  | 3/10       | 4/10  | 2/10      | Ok for code exploration. Never use for code review.                                    |
| GPT 6 Astra      | 5/10       | 0/10  | 7/10      | Ok for complex tasks: architecture, non-trivial coding, long-running agentic sessions. |
| GPT 5.6 Sol      | 3/10       | 2/10  | 6/10      | Ok for general-purpose coding. Needs explicit stop criteria.                           |
| GPT 5.6 Terra    | 2/10       | 5/10  | 4/10      | Good for light coding, mechanical changes.                                             |
| GPT 5.6 Luna     | 2/10       | 10/10 | 2/10      | Great as a subagent for code exploration and simple coding tasks.                      |

Other rules:

- Use subagents to protect the main session's context during large exploration, or when explicitly requested. Handle small tasks in the main session.
- Consult the model table above and the models available in the current client. Choose the least expensive model suited to the task. Never use an expensive large model for simple work.
- Start subagents with fresh context. Give each one a bounded task, the necessary facts and artifact paths, a stopping condition, and the expected result. Do not inherit or copy the conversation history, even when using the same model. In Codex, use `fork_turns: "none"`.
- Treat subagents as disposable workers. Keep requirements, decisions, and final synthesis in the main session. Have agents return concise findings, evidence or artifact paths, and blockers. Keep their raw tool output and working notes out of the main thread.
- Run at most 3 subagents at a time across the task, including nested agents. Close completed agents and start fresh ones as work progresses. Ask before exceeding the concurrent limit.
