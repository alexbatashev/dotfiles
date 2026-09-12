---
name: show-me-your-work
description: "Record consequential decisions and unrelated side quests in shared project files."
---

# Show me your work

Keep a durable record when the user requests it or when consequential decisions need to survive a long task. Log decisions, discoveries that change the approach, and verification outcomes. Skip routine tool calls.

Use `~/project-plans/<project>/_trails/<date>-<task>.tsv` for decision notes and `~/project-plans/<project>/side-quests.tsv` for unrelated work. Reuse the project's existing plan directory and name. Honor an explicitly requested location.

## Format and helper

Use [scripts/log.sh](scripts/log.sh) with six arguments:

```sh
bash scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>
```

Resolve the helper relative to this skill. It creates the parent directory and header, stamps the UTC time, keeps cells on one line, and escapes spreadsheet formulas. The columns are `ts`, `phase`, `decision`, `why`, `evidence`, and `result`.

Write what was decided in `decision`, its reason in `why`, and a source path or link in `evidence`. State the actual outcome or use `open` when unresolved. A correction is a new row that identifies and supersedes the earlier entry. Preserve the original.

## Side quests

For unrelated work, use phase `side-quest`. Describe the work, its impact, and where it was found. Check the existing list before adding an equivalent entry. Record later status changes as new rows referring to the original item.

Log the finding and return to the requested task. Do not pursue it, create an issue, or open another PR unless the user brings it into scope. Briefly mention the saved item when it matters to the user.

The main agent owns shared logs. Subagents return findings with evidence so the parent can record them without concurrent writes to one file.

## Review

Check entries against actual artifacts and available evidence. Use the current client's transcript only when needed to resolve what happened. Locate that session from its metadata, scope reads to the current workspace and task, and do not assume a Cursor-specific path.

Keep logs with the shared project plans. Commit or publish them only when requested or required by the project's delivery workflow. Link the relevant log in the handoff when it helps the user review the work.
