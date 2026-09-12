---
name: to-spec
description: Turn the current conversation into an implementation spec saved with the project's plans.
---

# To spec

Synthesize the decisions already made and inspect the relevant code to resolve factual gaps. Do not restart the conversation as an interview. Ask only when an unresolved choice materially affects the spec, and follow the user's requested interactive workflow.

Save the spec as Markdown under `~/project-plans/<project>/<plan-directory>/`. Reuse the relevant plan directory and honor a requested path or format. Publish to an issue tracker only when the user asks.

Include the parts needed to implement the feature:

- The user's problem and the intended observable result.
- The behavior and acceptance criteria, including important error cases.
- Consequential decisions about data, interfaces, ownership, and compatibility.
- Existing code or examples that clarify the intended design.
- Useful verification and the outcomes it should establish.
- Open questions and the scope boundaries that affect implementation.

Use the natural number of requirements. Do not pad the spec with an exhaustive list of user stories. Include a code snippet when it expresses a decision more precisely than prose. Verify file paths before citing them and keep mechanical steps brief.

Prefer existing test interfaces and evaluate tests by the behavior they prove. Do not require approval of routine test placement. Record unrelated work in the shared side-quest list.

When publication is requested, discover the project's tracker and label conventions. Do not invent a destination, label, or setup command. Prepare the spec before asking for a missing destination. Existing authorization to publish does not need another confirmation.
