---
name: review-feedback
description: Use when user directly asks to review past feedback
disable-model-invocation: true
---

# Review feedback

For each project feedback is persistently stored in `~/project-plans/<project name>/feedback.tsv`.
Each row has date when issue first occured, path to the conversation and other info that helps
diagnose the core issue.

Your goal is to analyze this feedback and prevent issues from happening in the future. This can
be resolved in one of the following ways.

## Issue resolution

First, read recent commits, reverts, review comments, agent instruction files, and comments that explain workarounds.
Group the mistakes into classes. A class counts once it has happened twice. Fix each class at the highest level that works.

### 1. Better code architecture

When the error is caused by unclear ownership rules or weak API contracts, the correct response
is to tighten it. Use `/architect` skill to propose a better design and record it persistently
for user to review later.

### 2. Add a lint rule

If some faulty behavior is deterministic, the correct way would be to enforce it programmatically.
Develop a strategy that includes: a test or a lint rule that uses existing tooling (like, clippy
or others), a way for agents to verify it locally (as part of usual routine, pre-commit hook, etc),
a schedule that checks it regularly in CI (pre-commit, post-commit or nightly).

Prefer well-established tools over hand-rolled bash or python scripts. If there's a tool that
provides a required lint but it is not used by the project, propose its use.

### 3. An agent hook

If agents repeatedly ignore some instruction to do a specific thing (run a command or something else),
add a hook that would trigger when certain conditions are met (tool use, prompt, etc). Hooks must
be designed in a way that works for both Codex and Claude Code. Refer to their documentation
to build it correctly:
- https://learn.chatgpt.com/docs/hooks
- https://code.claude.com/docs/en/hooks-guide#prompt-based-hooks

Hooks can be stored both inside project and globally. If the feedback if user preference, choose
to add a global hook (i.e., into ~/dotfiles). If it is project-specific opt-in for in-repo hook.

### 4. AGENTS.md change

If the feedback requires judgement and is not trivially enforcable, the only way to try and fix it
is to amend wording in AGENTS.md. Use it as the last resort. These changes are prone to error and
models generally ignore whatever is written in AGENTS.md.

### 5. A Claude Code plugin

This one is specific for Claude Code for now, but it allows creation of mods that change how harness
looks and works: add panes, commands, and tool call rules. Specifically, mods can draw an interface
user can use, redraw Claude Code's own interface, step into a tool call or a request, run their own
code on command like `/command`, share data between hooks. Only use these if #1-3 aren't capable of
doing what is required. Read detailed docs on mods if you choose this route: https://code.claude.com/docs/en/plugins/mods/overview

## Present review

Never act without users approval. Instead perform a deep analysis of the issues and their root causes.
Your final response to the user must be an enumerated list. It specifically names the failure mode
and describes the proposed solution. Once user reviewed the list, they can respond with something
like "fix #1-5 and #10". You only fix those and remove the corresponding lines from feedback.tsv.
