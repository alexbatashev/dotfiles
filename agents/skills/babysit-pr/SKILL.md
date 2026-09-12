---
name: babysit-pr
description: Monitor a requested PR and fix relevant CI failures or review findings until it is ready.
---

# Babysit a PR

Identify the requested PR and inspect its current head, checks, and review findings using the available forge tools. Monitor with waits appropriate to the expected check duration.

Investigate failures before changing code. Fix issues caused by the PR and verified review findings within its scope. Run affected checks and wait for required CI results on the updated head. Record unrelated work in the shared side-quest list.

If a tool is blocked by sandbox access, retry through the supported permission flow. A genuine authentication failure needs authentication to be restored. Do not assume every failure is a sandbox problem.

Finish when required checks pass and actionable in-scope findings are addressed, or when the PR closes or merges. Report a blocker when progress requires user input or an external change. Honor the requested watch duration if one was given. Merging or sending messages requires authorization from the user's request.
