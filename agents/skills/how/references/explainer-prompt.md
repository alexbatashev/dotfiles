# Explanation guide

Use this guide for a larger architectural explanation. Reuse findings already gathered in the main session or supplied by requested investigators.

---

Write an architectural explanation for an engineer unfamiliar with this part of the codebase. Combine the available evidence into a clear account.

## Original question

> {QUESTION}

## Findings

{FINDINGS}

## Instructions

Combine overlapping findings and resolve contradictions by checking the code. Distinguish confirmed behavior from inference and unanswered questions.

Write an explanation a senior engineer unfamiliar with this area could read and walk away with a solid mental model, understanding the architecture well enough to start working in it confidently.

Use available read-only tools to clarify details or fill gaps. Reuse existing evidence instead of repeating the investigation.

## Output format

Use this structure, adapted to what makes sense for the question. Not every section is needed for every question.

### Overview
1-2 paragraphs. What is this thing, what does it do, why does it exist. Someone should be able to read just this and decide whether to keep reading.

### Key concepts
The important types, services, or abstractions needed to follow the rest. Brief definitions, not exhaustive.

### How it works
The core of the explanation, and the longest section. Walk through the flow: what triggers it, what happens step by step, where data goes, what the decision points are.

Use prose, not pseudocode. Reference specific files and functions so the reader knows where to look, but don't dump large code blocks unless a snippet is genuinely essential to a point.

When the flow involves multiple components talking to each other, or data transforming through stages, include a diagram. Use mermaid (```mermaid) for structured flows (sequence diagrams, flowcharts, component graphs) or ASCII art for simpler relationships where mermaid would be overkill. Use your judgment. A diagram should clarify, not decorate. If prose covers the flow, skip the diagram.

### Where things live
A brief file/directory map. Just the ones someone would need to start working here.

### Gotchas
Non-obvious things, surprising behavior, historical context, sharp edges. Skip this section if there's nothing worth calling out.

## Communication style

- Use concrete language, not abstractions-about-abstractions
- Say "the `UserService` calls `AuthClient.refresh()`" not "the service delegates to the client"
- When something is complex, explain why it's complex. Don't just describe the complexity
- When something is simple, don't pad it out
- Prefer a literal explanation. Use an analogy only when it makes the mechanism easier to understand
- State material open questions or gaps in the evidence
