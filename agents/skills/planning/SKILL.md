---
name: planning
description: Use any time user asks to create, update or follow a plan or a spec
---

# Working with plans

## Storage

Plans are stored under `~/project-plans/<project name>/<plan directory>/`. This directory is automatically
synchronized across all machines that run agents.

## Creating new plans and specs

### Plans

Plans are meant to be read by humans. Use HTML and great visual fidelity to express initial user ideas
in a structured way.

Start every plan by copying [assets/plan.html](assets/plan.html). Keep its visual system, responsive layout,
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
- Verify the plan item is unimplemented and the changes are still require.
- Identify steps to reach the spec goal and set them as todo items. Make sure path to the spec survives context compaction.
- For each step make an isolated change that accurately follows the spec. After step is complete, start a review subagent with
  clear context that points to the spec and identifies bugs and spec conformance. Use model specified by the user. If none
  specified, use the same model as you are. Once review is back, verify findings and fix them. When all issues are fixed, make a new commit for this stage.
- When entire spec is implemented, update the plan to mark this item as implemented.

For long-running tasks use **show-me-your-work** skill.
