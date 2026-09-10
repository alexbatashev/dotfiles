---
name: create-pr
description: Use when user explicitly asks to create a PR
---

# Create PR

- Most PRs will most likely be squashed, so title becomes commit title and body becomes commit message
- Do not include any links to session or something like that. Do not attribute yourself in commit message
- Look for other commits to see how they are titled. Most likely that is conventional commits
- Describe *why* the change was needed, not what it does
- PR body should be concise. Provide an example or a clearer description if title was not enough. For simpler changes no body at all.
- Write PR descriptions for humans, not for agents. They must be clear, self-contained without any mentions of files, facts, events outside the repository.
