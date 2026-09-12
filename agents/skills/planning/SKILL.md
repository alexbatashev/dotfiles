---
name: planning
description: Create, update, or follow a requested plan or specification.
---

# Working with plans

## Storage

Plans are stored under `~/project-plans/<project name>/<plan directory>/`. This directory is automatically
synchronized across all machines that run agents.

## Creating new plans and specs

### Plans

Plans are meant to be read by humans. Use self-contained HTML by default and honor a requested format.

For an HTML plan, start from [assets/plan.html](assets/plan.html). Keep its visual system, responsive layout,
light and dark themes, and syntax-highlighting script intact. Replace every bracketed placeholder, remove sample
content that does not apply, and add sections only when the work needs them.

The plan must remain a self-contained HTML file. Do not add network dependencies, external fonts, or separate
stylesheets and scripts. Mark C++ blocks with `class="language-cpp"` and Rust blocks with
`class="language-rust"`.

Each implementation step must name a measurable outcome, the concrete changes that produce it, and the command
or observation that proves it worked. Keep the template's fixed reading order: goal, current and target state,
implementation, verification, risks, and scope.

If user asks to create an isolated prototype (not based on the source of the project), store the prototype near the plan.

### Specs

Specs are meant to be handed out to agents to implement. Write specs in Markdown. A good spec has:

- A measurable goal: performance target, well-defined new feature behavior.
- Step-by-step guide to implementing the spec with pointers to source code.
- Detailed description of algorithms and data structures used in the solution.
- Proposal for testing if the task makes sense to create a new test.
- Expected outcomes.

## Following a plan

Whenever you are asked to follow a particular plan, you need to follow the protocol:

- Read the plan and attached spec if it exists.
- Check which plan items remain and whether the proposed changes are still needed.
- Identify steps to reach the spec goal and set them as todo items. Make sure path to the spec survives context compaction.
- Work in coherent units. Review the diff against the intended outcome and run relevant checks. Commit according to the user's request and the project's delivery workflow. Delegate large exploration under the user's agent preferences. Independent review is optional when requested, not a requirement after every step.
- When entire spec is implemented, update the plan to mark this item as implemented.

Record consequential discoveries and changes of approach with **show-me-your-work**. Put unrelated work in the shared side-quest list. Continue toward the requested outcome when evidence calls for a different method, and ask about material choices the user needs to make.
