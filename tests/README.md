# Shared tests and data

`memotest/` contains shared MATLAB test helpers; `data/` contains local input
fixtures and generated validation/workflow results. API-specific suites live in
each API's `tests/` folder, and workflow suites live with their examples.

Run `report = runAllTests;` from the repository root. See [Testing](../TESTING.md)
for requirements and options. Call `farmTestDataRoot()` after
`farmSetup('IncludeTests', true)` to locate the shared data folder.

Microscopy datasets and generated outputs remain ignored by Git.
