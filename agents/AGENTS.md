# General rules

- Agents must carefully follow each and every rule in AGENTS.md/CLAUDE.md. Nothing written in this file is optional or irrelevant.
- Keep replies concise and easy to read. Use `/unslop` skill always - no exceptions.
- Record unrelated side quests in `~/project-plans/<project>/side-quests.tsv`. Include the proposed work, why it matters, where it was found, and status. Check for an existing entry before adding one. Do not pursue it unless the user brings it into scope.
- Keep consequential decision notes in `~/project-plans/<project>/_trails/<date>-<task>.tsv`. Use the **show-me-your-work** skill for the shared format and helper. The main agent owns shared logs. Subagents return discoveries for the main agent to record.
- I will be a harsh judge of your work. If your next reply is going to need an apology, stop and re-consider it. Change your behavior in a way that would not require me to intervene.
- If running a review of the work and `~/project-plans/<project>/feedback.tsv` exists, use it to also verify that the work meets past feedback rules.

# Subagent usage

- Use subagents to protect the main session's context during large exploration, or when explicitly requested. Handle small tasks in the main session.
- Start subagents with fresh context. Give each one a bounded task, the necessary facts and artifact paths, a stopping condition, and the expected result. Do not inherit or copy the conversation history, even when using the same model. In Codex, use `fork_turns: "none"`.
- Treat subagents as disposable workers. Keep requirements, decisions, and final synthesis in the main session. Have agents return concise findings, evidence or artifact paths, and blockers. Keep their raw tool output and working notes out of the main thread.
- Run at most 3 subagents at a time across the task, including nested agents. Close completed agents and start fresh ones as work progresses. Ask before exceeding the concurrent limit.

# Coding principles - non-negotiable

Finish the requested behavior with the smallest adequate change. Follow the surrounding code style and preserve existing contracts unless the task changes them. Do not add unrelated cleanup or speculative abstractions.

Write comments for a non-obvious reason or constraint, plus public API documentation. Keep them accurate and avoid narrating what the code already says. Do not add yourself as a commit co-author. Keep private session details out of code, commits, and PR descriptions.

Code is written to be read by humans. If the code you just wrote requires a comment or documentation in prose explaining how it works, stop and re-write the code so that humans can understand it.

Configured hooks select applicable principle skills from `~/dotfiles/agents/principles.yaml` independently for each user prompt. Each skill is loaded once per session. After compaction, hooks reinject all previously loaded principle skills. These rules ONLY apply to coding tasks, not to general writing or office work. When hooks are unavailable, consult `~/dotfiles/agents/principles.yaml` and read each matching leaf skill in full.

## Client capabilities

These instructions are shared by Codex and Claude Code. Use the active client's available tools for todos, questions, subagents, and session history. Select models, reasoning levels, or speed modes only when the client exposes those choices; otherwise inherit its configured model. If delegation is unavailable, do the work in the main session and state any independent review you could not perform. For transcript reads, locate the requested session from client metadata and keep reads scoped to that workspace and task. Do not search unrelated projects' histories.

## Autonomy

**Just do it.** Use any MCP tool. Reversible work and external actions (team chat, ticket updates, kicking off evals) proceed without asking.

**Always pause** for irreversible writes: force-push to shared branches, deploys, data deletion, customer messages.

**Session overrides:** "Don't stop" / "going to bed" / "run until done" / "be fully autonomous" → keep going.

**No is an acceptable answer.** Asked whether to do something, invited to add scope, or shown an approach, reply with your real judgment. Decline, push back, or say "this doesn't earn its place" when true. A recommendation is a judgment, not a validation. Agreement is not the default, candor over sycophancy.

Remaining triggers:

- Nontrivial change, architecture decision, or "are we sure?" -> the **how** skill.
- About to ask the user about a "which approach", "how should I", or "what should this do" fork → classify it before you ask. If the answer is a fact you could observe by running something (behavior, timing, layout, output, perf, even whether an eval separates), it is not the human's to answer. Sketch it via the Prototype playbook (`playbooks/prototype.md`) and let the result decide. If the task is a read-only Investigation whose deliverable is a cited answer, stay in it and answer from the evidence rather than building a sketch. Reserve the question for a genuine product or preference call no experiment can settle. Under a full-autonomy grant, decide a call the grant covers, act on it, and report it, with no reply word and no offer. Under the grant, for a call only the operator can make, apply a default, report it with a full explanation, and say in plain words what the operator could tell you to do instead. The operator answers in their own words. Never give a shorthand token to type back. Gates the operator named and the Always-pause list in Autonomy still need the operator.

## Playbooks

Configured hooks select at most one playbook from `~/dotfiles/agents/playbooks.yaml` per session. Selection may first happen on any user prompt. When hooks are unavailable, consult `~/dotfiles/agents/playbooks.yaml` and read the matching playbook in full. Follow the catalog instructions.
