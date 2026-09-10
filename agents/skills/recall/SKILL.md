---
name: recall
description: "Reconstruct your recent working context from your own chat history, live state, and the shared record (user reports, prior fixes, incidents), then hand back a tight current-state brief. Use for 'recall my work on X', 'catch me up', 'what have I been working on', 'where did I leave off', before starting or resuming work."
disable-model-invocation: true
---

# Recall

**Before you start or resume work, you rebuild the user's recent working context and hand back a tight capsule of where things stand now and what to do next.** Use for "recall my work on X", "catch me up", "what have I been working on", or "where did I leave off".

Keep it tight and on-topic. Read only what the in-scope threads need, then stop. Filter transcripts with local searches or scripts and read only matching regions. Use subagents only when the user explicitly requests them.

Your context lives in two records. Your own chat history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the **why** skill searches, across source control, the issue tracker, chat and issue channels, long-form docs, and error tracking. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your transcripts alone.

Chat history lives in the active client's local store:

- Claude Code: `~/.claude/projects/<slug>/*.jsonl`, where `<slug>` is the absolute workspace path with "/" replaced by "-" (so `/Users/you/proj` becomes `-Users-you-proj`).
- OpenCode: `~/.local/share/opencode/opencode.db`. Query `session` by its exact `directory`, order by `time_updated`, then join `message` and `part` by `session_id`. Do not copy or rewrite the database.
- Codex: `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`. Filter on the `cwd` in each rollout's `session_meta` payload, order by file modification time, and use `turn_context` records to find turn boundaries.
- Decision trails: `~/project-plans/<project name>/_trails/`. Filter by relevant dates. Skim over these files to highlight non-obvious decisions that user needs to be aware of.

1. Classify, then route. One specific prior chat to resume is the `session-pickup` playbook, not this. Turning habits into a durable skill is `automate-me`. A human-readable summary of your work is a different task. Recall loads working context across recent chats before you act. If the user already gave you a full state capsule (paths, branch, the change), use it and skip the mining.
2. Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, and the workspace (default the active one; never read another project's transcripts without being asked). State the scope back. Never quietly turn "all" into "recent N".
3. Search chat history directly. Order candidates by actual modification or update time, never UUID. Filter by workspace, time window, and topic before reading matching regions. Skip the current chat and obvious subagent, eval, and test noise. Extract goals, decisions, open threads, corrections, and artifacts, citing chat UUIDs.
4. Follow relevant PRs, tickets, and unresolved claims into the shared record when needed to establish current state. Use the **why** skill's source playbooks for those searches. Do not launch a full source sweep merely because the topic names a feature or file.
5. Verify against live state. A transcript or a stale ticket is history, not current truth, so take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), read the full transcript, not just a trimmed local copy.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep reporting and any fix that shipped and was reverted, so the next attempt starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Write the brief through the **unslop** skill, cite chat findings by UUID and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above.
