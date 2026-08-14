---
name: babysit-pr
description: Use when user asks to watch, monitor, or babysit PR
---

# Babysit a PR

- Whenever user asks to babysit a PR use gh tool to find the PR and fetch CI logs.
- If gh fails with authentication error, try with elevated permissions outside sandbox. gh is always authenticated on my machines.
- Wait for CI to complete and fix failing tests if any.
- Fix PR comments if there are any.
- Avoid scope creep. Only fix issues, but do not add new features.
