---
name: why
description: Investigate historical design choices or regressions from cited evidence. Use how for runtime behavior.
---

# Why

Answer the motivation question from evidence. Delegate bounded source searches when large exploration would consume the main session's context, or when requested. Follow the user's model and agent-count preferences. Keep synthesis in the main session.

1. Anchor the question in the relevant code, symbols, and behavior. Reuse existing findings instead of repeating exploration.
2. Start with the closest evidence: git history, the introducing PR, and linked tickets or design documents. Check available tools before assuming a source is accessible.
3. Follow references and unresolved questions into other sources as needed. Search all available categories only when the user requests a comprehensive investigation. Stop when the evidence supports the answer, or report the remaining uncertainty.
4. Synthesize the answer yourself. Separate documented reasons, inferences, and unknowns. Cite evidence for historical claims. Code behavior alone does not prove intent. An empty search does not prove no discussion occurred.
5. Briefly state which sources were searched and any material gaps. If a change is planned, identify constraints to preserve and risks the history reveals.

Read [the confidence guide](references/epistemics.md) when weighing ambiguous evidence. Use [the source playbooks](references/source-playbook.md) only for sources the investigation needs. For incident-driven behavior, consult [the incident playbook](references/sources/incident-postmortem.md).

When delegating, assign bounded, non-overlapping source questions using [the investigator template](references/investigator-prompt.md). Pass only the relevant code anchors and source playbook. Verify returned citations and combine findings in the main session.
