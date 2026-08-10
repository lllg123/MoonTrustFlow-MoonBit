# Contributing to MoonTrustFlow

MoonTrustFlow is a small MoonBit Policy-as-Code library. Contributions should
keep the policy language deterministic, the public API reviewable, and the
repository runnable on all CI targets.

## Development workflow

1. Install the pinned MoonBit toolchain `0.10.3+16975d007`.
2. Keep changes focused in the relevant package files and add a fixture or
   test for new behavior.
3. Run the full local acceptance script with the pinned toolchain:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\verify_acceptance.ps1
   ```

4. Run the fixture corpus check directly when changing models or adapters:

   ```powershell
   python scripts\verify_fixture_corpus.py
   ```

5. Review `moon fmt` and `moon info` diffs before committing. Public API
   changes must be intentional and reflected in README or design documents.

## Pull requests

- Explain the behavior change and its scope.
- Include deterministic tests and, where applicable, a representative `.mtf`
  fixture with an expected summary in `fixtures/benchmarks/manifest.json`.
- Do not commit generated `_build/` output, credentials, or unrelated files.
- Preserve the Apache-2.0 license and the attribution information in NOTICE.

## Scope boundary

The project analyzes an explicit trust-flow model. It is not a compiler
frontend or a whole-program static analyzer. AST and call-graph adapters should
translate into the stable `.mtf` model instead of expanding the core package
with platform-specific I/O.
