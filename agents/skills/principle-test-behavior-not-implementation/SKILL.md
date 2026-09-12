---
name: principle-test-behavior-not-implementation
description: Assess a test by the observable behavior or contract violation it can detect.
---

# Test behavior, not implementation

Exercise the supported interface and assert the result, effect, or contract the caller relies on. Choose expected values independently of the implementation.

Ask which plausible defect would make the test fail. For a regression, demonstrate failure before the fix when practical. A weak assertion may catch some defects while missing the one the test needs to detect.

Keep useful property, absence, error, protocol, and compile-time tests. A mock can verify a meaningful interaction contract, but checking an incidental internal call couples the test to the implementation.

Avoid tests that only restate prompt wording, configuration, mock setup, or a value computed by the same code under test. Test the behavior that depends on that input when it matters. Add or retain a test when its defect-detection value justifies its maintenance cost.
