# Changelog

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
