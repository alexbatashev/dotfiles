# Design candidate prompt

Use this template only when independent design candidates are requested. Start with no conversation history and follow the user's model preferences and agent limit.

- Design question: {QUESTION}
- Required behavior and constraints: {CONSTRAINTS}
- Relevant code and evidence paths: {REFERENCES}
- Owned output directory: {OUTPUT_DIRECTORY}
- Stop when: {STOP_CONDITION}

Write the caller's usage first, then derive a candidate interface and data model. Use [the rationale template](rationale-template.md) for the decisions that need explanation. Keep implementation out unless assigned.

Work only in the assigned output directory. Record uncertainty and verify claims against the provided evidence. Return a concise recommendation, the consequential tradeoffs, artifact paths, and blockers. The main agent compares candidates and decides the final shape.
