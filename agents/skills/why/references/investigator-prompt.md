# Investigator prompt

Use this template for a bounded historical investigation. Start the agent with no conversation history. Pass only the fields relevant to its assignment and the source playbook it needs.

- Question: {QUESTION}
- Relevant files and symbols: {CODE_ANCHORS}
- Known evidence: {EVIDENCE_PATHS_OR_LINKS}
- Assigned source and search boundary: {SOURCE_SCOPE}
- Stop when: {STOP_CONDITION}

Investigate the assigned question with read-only tools. Use targeted searches, read evidence in enough context to interpret it, and preserve contradictions. Follow leads within the assigned scope. Return other leads for the main agent instead of starting additional agents.

Code behavior establishes what happens, not why it was designed that way. Distinguish documented reasons from inferences and unknowns. Quote only when exact wording matters and include a precise citation.

Return a concise answer with supporting source locations, material gaps, and blockers. Keep bulk evidence in an artifact when needed and return its path. Do not send raw tool output or repeat the prompt. The main agent owns final synthesis and the shared side-quest log.
