# MoonTrustFlow Implementation Plan

## Current Scope

MoonTrustFlow v1 is implemented as a MoonBit library plus a small CLI demo. The
core scope is a policy model evaluator rather than a source-code parser.

Implemented components:

1. `.mtf` line parser with quoted text and diagnostics.
2. Domain model for nodes, edges, policies, models, and findings.
3. Policy evaluation for `deny`, `require`, and `allow`.
4. CLI demonstration under `cmd/main`.
5. Blackbox tests for parser behavior, policy evaluation, and report output.
6. Competition documents and CI workflow.

## Design Choices

- The parser is dependency-free to keep the package easy to build.
- Policy evaluation is deterministic so CI output is stable.
- `allow` uses exact path matching to avoid accidentally hiding broad risks.
- The project keeps a clear adapter boundary for future AST, call-graph, or
  architecture extraction inputs.

## Acceptance

- `moon test` passes.
- `moon run cmd/main` prints a deterministic policy-evaluation demo.
- `README.md` is a normal tracked file.
- Competition materials use the GitLink and GitHub repositories supplied for
  submission.
- Git history remains in the 10-20 effective commit range required by the
  organizer.
