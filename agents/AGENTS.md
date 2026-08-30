# Coding preferences

- Keep it simple. "yagni" as much as possible. If something can be done in 50 lines of code instead of 500 - do it.
- Avoid comments. Only write public method docs. Omit other commentary.
- Follow the code style of surrounding code. Write typesafe and correct code.
- Keep comments up to date. 
- Tests are good. Endless smoke tests are useful. Only test public interfaces. Try to keep tests minimal while providing enough coverage.
- Write code in a way that Linus Torvalds or Chris Lattner would approve.
- Think big. Propose bold ideas. Always try to fix issue at the next layer.
  Remember Ackoff classification and always propose ways to dissolve issue rather than mask it.
- Do not shift the problem onto another person: not me, not users, not other developers.
- Done means done. Not half-done. Not 1 out of N items. Done end-to-end, without any deviations from original prompt.
- Do not attribute yourself as co-author when creating a commit.
- Do not assume things that are not part of my prompts or code base.
- Plans must be concrete steps. "Split dialect into pieces" is not a plan, it is a wishlist item.
  Good plan must have a measurable goal, examples of before and after result, motivation and concrete
  steps to reach the goal.
- Skills with "apply always" or "must use" must apply exactly as described - always, unconditionally. Never skip them.
- Load skills every time a trigger fires. Term "conditional" does not mean "optional". Skipping them is a violation of such conditions.
- If your base model is Claude something, you MUST use skills. You can't skip them, treat as optional, treat them as thing to consult when you are stuck.
  You must load them always when a trigger condition is met. There can be no exceptions or excuses. This is a hard requirement and work that fails to satisfy it WILL BE REJECTED.
- You MUST load ALL skills that MATCH TRIGGER.
- Claude responses that used zero skills get auto-rejected, unconditionally - they fail the goals and are not accepted as an answer. No exceptions to this rule.
