# MoonTrustFlow Design

## Summary

MoonTrustFlow is a compact rule-model data-flow analyzer for MoonBit. It models
security-relevant flows without requiring a full language frontend in v1.

## Model Language

Each non-empty line starts with a directive:

- `source <name> "<description>"`
- `sink <name> "<description>"`
- `sanitizer <name> "<description>"`
- `node <name> "<description>"`
- `edge <from> -> <to> "<label>"`
- `allow <node> -> <node> ...`

The syntax intentionally stays small so the parser and diagnostics are easy to
review.

## Analysis

The analyzer starts from every source node and walks outgoing edges. It records
the path, stops at sanitizer nodes, reports when a sink is reached, and
suppresses paths that exactly match an allow policy.

## Boundaries

The first version does not parse real MoonBit source files. That is a deliberate
scope choice: the package provides a tested analysis kernel that can later be
fed by AST, call graph, or architecture extraction tools.
