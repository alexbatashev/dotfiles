---
name: principle-build-the-lever
description: "Automate repeated work or checks when a script improves reliability or makes the result easier to verify."
---

# Build the lever

Use an existing tool first. Build a small script when deterministic execution improves reliability, repeated work, or verification enough to justify maintaining it.

- Try a representative case to understand the operation before automating it.
- Check the tool against a known result and make it safe to rerun.
- Prefer one script to multiple agents applying the same mechanical edit.
- Keep the command and relevant output available so a reviewer can repeat the check. Retain the script when future work will use it.

A nontrivial task does not always need a new tool. Direct inspection or an existing test can be sufficient. Keep the tool smaller than the problem it solves.
