# MoonTrustFlow Implementation Plan

## Current Scope

MoonTrustFlow is implemented as a MoonBit library plus a repository CLI entry.
The core library stays focused on policy parsing, graph traversal, and finding
generation. Real file ingestion is handled by repository scripts that bridge
fixture content into the CLI, so the library itself remains cross-target
friendly.

Implemented components:

1. Focused MoonBit source files for types, parsing, path search, analysis, and reporting.
2. `.mtf` parser with deterministic diagnostics.
3. Policy evaluation for `deny`, `require through=`, and exact-path `allow`.
4. Text and JSON finding output.
5. Complex fixture scenarios for branching, multi-sink, and cycle-pruning flows.
6. Acceptance, contributor-identity, and repository verification scripts.
7. Competition-facing documentation and CI workflow.

## Design Choices

- Keep the core analysis package dependency-light and portable.
- Keep `allow` exact rather than broad to avoid hiding real findings.
- Separate sample-mode CLI behavior from file-backed wrapper behavior so `moon run cmd/main` remains easy to run everywhere.
- Prefer evidence-producing scripts over informal checklist prose.

## Acceptance Baseline

- `moon check --target all` completes cleanly.
- `moon test` passes locally.
- `moon fmt` produces no diff.
- `moon info` produces no diff.
- `moon run cmd/main` prints the embedded deterministic sample analysis.
- `scripts/analyze_model.ps1` can analyze a real `.mtf` fixture and emit JSON.
- `scripts/verify_acceptance.ps1` checks required files, contributor identities, Mooncakes visibility, remote defaults, and tracked MoonBit source scale.

## Known Local Constraint

On this Windows machine, `moon test --target all` still depends on a system C
compiler for the native target. The repository therefore treats:

- local baseline: `moon test`
- CI baseline: `moon test --target all`

This constraint is recorded rather than hidden.

