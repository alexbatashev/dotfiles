# Rationale template

Use the parts needed to explain a consequential design. Replace the notes with actual findings.

## Problem

State the requested outcome and the constraints established by the investigation. Separate observed facts from assumptions that still need checking.

## Usage

Write the caller's usage first. Show the calls, inputs, results, and errors needed to understand the interface. Derive the design from that usage.

## Shape

Describe the data structures, ownership, and important operations. State which invariants the types enforce and where external data is validated. Explain what complexity the interface hides and what callers must still understand.

## Decision and alternatives

Explain why the chosen approach fits the requirements. Include alternatives when they affected the decision and state why they were rejected. Do not invent alternatives to fill a quota.

## Tradeoffs and open questions

Name accepted costs and unresolved choices that could change the result. Distinguish questions for the user from facts that can be investigated. Record unrelated ideas in the shared side-quest list.

## Implementation

If implementation is in scope, name the next coherent steps and the observations that establish completion. Otherwise deliver the design without starting implementation.
