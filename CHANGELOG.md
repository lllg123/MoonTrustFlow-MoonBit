# Changelog

## 2026-08-11

- Added a nine-fixture benchmark and boundary corpus with manifest-backed summary regression checks.
- Mirrored the corpus and documentation updates across the GitHub and GitLink repository copies.
- Added `CONTRIBUTING.md` and `NOTICE`, expanded acceptance documentation, and added edge tests for empty, disconnected, quoted, CRLF, comment, and default-severity inputs.
- CI and `scripts/verify_acceptance.ps1` now execute the complete fixture corpus.
- Switched CI to the official MoonBit installer pinned to `0.10.3+16975d007`, ensuring the 0.10.3 core/prelude bundle is installed on Linux, macOS, and Windows runners.
- Reduced push-triggered duplicate runs by checking the GitHub default branch (`main`); manual dispatch remains available.

- Restored the MoonBit 0.10.3-compatible executable package declaration in `cmd/main/moon.pkg`.
- Hardened CI with `--deny-warn`, explicit native compiler setup, workflow dispatch, and both default branch names.
- Refreshed acceptance evidence with the official OSC2026 schedule, current 1220-line MoonBit scale, and current contributor/default-branch audits.

## 2026-07-28

- Updated `cmd/main/moon.pkg` to the current executable-package form while keeping `moon run cmd/main` cross-target friendly.
- Added `analyze_text` and a deeper long-path test to strengthen reusable analysis entry points and path-search coverage.
- Added cross-platform repository wrappers for real `.mtf` input, call-graph JSON import, and benchmark smoke testing.
- Tightened contributor-identity auditing to include the live GitHub contributors API and acceptance-script enforcement.
- Refreshed CI to pin MoonBit `0.10.3+16975d007` and validate fixture analysis through the repository wrapper.

## 2026-07-10

- Split the MoonBit core into focused parsing, path-search, analysis, and reporting files.
- Added complex taint-propagation fixtures covering multi-sink, allow-exception, and cycle-pruning cases.
- Added JSON report output and an env-bridged CLI flow for analyzing real `.mtf` files through repository scripts.
- Upgraded local acceptance materials for the current OSC2026 rule wording and MoonBit 0.10.3-compatible command set.
- Prepared contributor-identity and acceptance verification scripts for GitHub and GitLink self-checking.

## 2026-07-06

- Refreshed acceptance-facing competition evidence and repository wording.

## 2026-07-05

- Polished competition completion materials and synchronized public repository metadata.
