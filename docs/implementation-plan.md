# MoonTrustFlow Implementation Plan

## Steps

1. Scaffold a clean MoonBit module under `python123/moontrustflow`.
2. Write blackbox tests for parser, diagnostics, analysis, policies, and report
   formatting.
3. Implement the domain model and parser.
4. Implement taint propagation and finding formatting.
5. Add CLI demo.
6. Add README, competition docs, application PDF/DOCX, and CI.
7. Run final verification and commit at least 10 meaningful commits.

## Acceptance

- `moon test` passes.
- `moon run cmd/main` prints a deterministic demo.
- README is a normal file.
- No residue from previous rejected projects remains.
- Git history has at least 10 commits before submission.
