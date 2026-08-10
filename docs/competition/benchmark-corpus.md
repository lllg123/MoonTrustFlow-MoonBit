# Benchmark and Boundary Corpus

This repository contains a deterministic fixture corpus for acceptance review.
The corpus is intentionally made from representative engineering scenarios,
not copied production data: no customer payloads, proprietary source, or
third-party project code is bundled.

## Coverage

| Scenario | What it checks |
| --- | --- |
| `webapp_taint.mtf` | HTML output and SQL query paths in a web service |
| `branching_flow.mtf` | Multiple sinks, branches, and three reviewed safe paths |
| `cyclic_reviewed_flow.mtf` | Retry cycle pruning and exact-path exception handling |
| `service_callgraph_imported.mtf` | JSON call-graph adapter output |
| `web_service_security.mtf` | HTTP, database, and audit-stream controls together |
| `message_pipeline.mtf` | Webhook validation and dead-letter persistence boundaries |
| `disconnected_input.mtf` | Unreachable policy path produces no false finding |
| `comment_and_escape.mtf` | Quoted text, escaped quotes, CRLF, and inline comments |
| `empty_model.mtf` | Empty but valid input remains deterministic |

The expected node, edge, policy, and finding counts are stored in
`fixtures/benchmarks/manifest.json`. This makes the corpus a regression
artifact rather than a collection of examples that only need to parse.

## Reproduce

With MoonBit `0.10.3+16975d007` installed:

```powershell
python scripts\verify_fixture_corpus.py
```

The command executes every model through `moon run cmd/main -- --json` and
fails if any summary differs from the manifest. The same command runs in CI
and inside `scripts/verify_acceptance.ps1`.

## Limits

The corpus validates the stable model language and repository adapters. It is
not a claim of whole-program static-analysis coverage. A future AST or
call-graph importer can add independently licensed real projects without
changing the core `.mtf` contract.
