---
name: recall
description: "Reconstruct prior work from chat history and current evidence when asked to recall work, catch up, or resume missing context."
---

# Recall

Reconstruct the user's prior work when asked to recall it or when missing context prevents resuming it. Report where things stand and what to do next.

Read only what the in-scope threads need, then stop. Filter transcripts before reading. Delegate large exploration under the user's agent preferences, with separate scopes for each investigator.

Your context lives in two records. Your own chat history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the **why** skill searches, across source control, the issue tracker, chat and issue channels, long-form docs, and error tracking. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your transcripts alone.

Chat history lives in the active client's local store:

- Claude Code: `~/.claude/projects/<slug>/*.jsonl`, where `<slug>` is the absolute workspace path with "/" replaced by "-" (so `/Users/you/proj` becomes `-Users-you-proj`).
- OpenCode: `~/.local/share/opencode/opencode.db`. Query `session` by its exact `directory`, order by `time_updated`, then join `message` and `part` by `session_id`. Do not copy or rewrite the database.
- Codex: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`. Filter on the `cwd` in each rollout's `session_meta` payload, order by file modification time, and use `turn_context` records to find turn boundaries.
- Decision trails: `~/project-plans/<project name>/_trails/`. Filter by relevant dates. Skim over these files to highlight non-obvious decisions that user needs to be aware of.

1. Match the search to the request. For one specific prior chat, read that chat directly. Search across recent chats when reconstructing broader working context. If the user already provided the paths, branch, change, and current status, use that context instead of mining history.
2. Set the scope before searching. For "recent," default to the last 7 days and say so. Use the named topic and active workspace unless the user specifies another scope. Do not read another project's transcripts without being asked or silently narrow a request for all history.
3. Search chat history directly. Order candidates by actual modification or update time, never UUID. Filter by workspace, time window, and topic before reading matching regions. Skip the current chat and obvious subagent, eval, and test noise. Extract goals, decisions, open threads, corrections, and artifacts, citing chat UUIDs.
4. Follow relevant PRs, tickets, and unresolved claims into the shared record when needed to establish current state. Use the **why** skill's source playbooks for those searches. Do not launch a full source sweep merely because the topic names a feature or file.
5. Verify against live state. A transcript or a stale ticket is history, not current truth, so take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), read the full transcript, not just a trimmed local copy.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Current state.** Explain what the work is and where it stands.
- **Threads.** State the current status of each relevant thread. Use labels that fit the work, such as merged, in progress, blocked, or planned. Include a PR or branch when relevant.
- **Problems.** Include recurring symptoms and reverted fixes that affect the next attempt.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Write the brief through the **unslop** skill, cite chat findings by UUID and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above.
