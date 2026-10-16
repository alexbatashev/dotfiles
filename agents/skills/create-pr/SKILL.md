---
name: create-pr
description: Prepare and create a pull request when the user asks for one.
---

# Create PR

Inspect the final diff, relevant checks, repository template, and recent commit titles. Use the project's conventions. Many PRs are squashed, so make the title suitable as a commit title.

Explain the problem and resulting behavior, followed by relevant validation. Use an example when it clarifies the change. Keep a simple PR to a short paragraph and follow the repository template when present. Use plain formatting. No headings, no bullets, no sections. Stay focused on topic. No "validation" section, no mention of things outside the repository.

Write for a reviewer who has not seen the conversation. Keep private chat history, local session links, and agent narration out. Reference an issue or external source when it provides relevant context and is appropriate for the repository's audience.

Do not add the agent as a commit co-author. Create the requested PR and report its link. Creation does not imply permission to merge or send separate messages.

## Stacked PRs

Use a stack when the user asks for one or when a large change splits into dependent layers that reviewers can check one at a time. Put foundational changes, such as shared types or schema, in lower layers. A layer may depend only on its own branch or branches below it. All branches must live in the same repository, so a stack cannot span forks.

GitHub shows each PR's diff against the branch directly below it. The bottom PR targets the trunk, usually the default branch. Branch protection, CODEOWNERS, and CI for the trunk apply to every PR in the stack. Write each description for its own layer and say where it sits in the stack.

Use the `gh stack` extension (`gh extension install github/gh-stack`, needs `gh` 2.0+ and Git 2.36+). Avoid the commands that need an interactive terminal: `modify`, `switch`, and `checkout` or `view` without arguments.

- `gh stack init [-b <trunk>] [branches...]` starts a stack, adopting existing branches bottom to top.
- `gh stack add [-A | -u] [-m <msg>] <branch>` creates the next branch on top. Run it from the topmost branch.
- `gh stack submit --auto` pushes all branches and creates or updates the PRs and the stack on GitHub.
- `gh stack link [--base <trunk>] <branch-or-pr>...` groups existing PRs into a stack, listed bottom to top.
- `gh stack rebase [--upstack | --downstack]` cascades a rebase after editing a lower layer. Resolve conflicts, then run `--continue`, or `--abort` to restore all branches.
- `gh stack sync [--prune]` fetches, rebases onto a moved trunk, pushes, and updates PR state.
- `gh stack view --json` and `gh stack up`, `down`, `top`, `bottom` inspect and move through the stack.

Merging goes bottom up. Merging a PR also merges every PR below it, and the PRs above retarget to the trunk. Only run `gh stack merge` when the user asks for a merge.
