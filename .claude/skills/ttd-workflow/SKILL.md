---
name: ttd-workflow
description: Enforce Test-Driven Development (TDD) rules and development cycle for new features.
---

# TDD Development Rules

All new features MUST follow Test-Driven Development.

### Development Cycle

For every behavior:

1. Understand the requirement.
2. Identify the smallest testable behavior.
3. Write the test BEFORE production implementation.
4. Run the test and verify that it fails.
5. Implement the minimum production code required to pass.
6. Run the test and verify that it passes.
7. Refactor the implementation if necessary.
8. Run the relevant test suite again.

### Rules

- Never implement a feature first and add tests afterward.
- Do not write unnecessary production code.
- Do not add tests that test implementation details unnecessarily.
- Tests should primarily verify observable behavior.
- Keep each test focused on one behavior.
- Preserve existing tests.
- If an existing test fails after a change, investigate the regression before continuing.
- Do not modify tests simply to make them pass unless the requirement itself has changed.
- Do not implement unrelated improvements while working on a feature.
- Before considering a feature complete, run the relevant test suite.

### Before Coding

First inspect:
- existing project structure
- existing tests
- testing framework
- coding conventions
- related modules

Do not modify code until the testing strategy is clear.

### Completion Report

After implementation, report:

- Tests added
- Production code changed
- Tests executed
- Test results
- Any remaining issues
