---
name: principle-guard-the-context-window
description: "Control large searches and reads to keep relevant evidence in the main session."
---

# Guard the context window

Filter before reading. Use targeted searches, bounded output, and local scripts to extract relevant sections. Save bulk output to files instead of printing it into the conversation.

Delegate large exploration when it protects the main session's context. Follow the user's model preferences and agent limit. Start each investigator with fresh context and a bounded question. Pass only relevant facts and artifact paths. Request a concise result with evidence, not raw output or a transcript. Keep decisions and synthesis in the main session. A script is usually better for mechanical filtering.

Keep frequently needed facts in a skill's entrypoint. Move substantial conditional detail into references and read only what the task needs. Reuse evidence already gathered instead of repeating exploration.
