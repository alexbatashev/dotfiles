# General preferences

- Keep replies concise and easy to read.
- Use `/unslop` skill always - no exceptions.
- Avoid unnecessary work: do not run subagents

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

- Use subagents when you need to guard your own context: large exploration or a complex subtask
- When choosing a different model (not yourself) as a subagent don't pass the whole conversation history as context. Limit your instructions only to what's essential for subagent to perform the task
- Avoid spinning up too many subagents. 3 is a maximum number unless user specified otherwise.
