# MoonTrustFlow Design

## Summary

MoonTrustFlow is a small Policy-as-Code engine for trusted data flow governance
in MoonBit projects. It does not try to replace a full compiler frontend or
general static-analysis framework. Instead, it defines a reviewable policy model
that can be produced by humans today and by source-code adapters later.

## Model Language

Each non-empty line starts with one directive:

- `source <name> "<description>"`
- `sink <name> "<description>"`
- `sanitizer <name> "<description>"`
- `boundary <name> "<description>"`
- `node <name> "<description>"`
- `edge <from> -> <to> "<label>"`
- `deny <from> -> <to> severity=<level> "<reason>"`
- `require <from> -> <to> through=<node> severity=<level> "<reason>"`
- `allow <node> -> <node> ... "<reason>"`

The syntax is deliberately line-oriented so diagnostics remain stable and the
parser can be audited easily.

## Evaluation Model

The analyzer evaluates policies over the directed graph:

- `deny` reports every reachable matching path unless an exact `allow` rule
  exists.
- `require` reports matching paths that do not pass through the required control
  point.
- `allow` is an exact exception mechanism, not a broad wildcard.

Two-node policies such as `deny a -> b` match any path from `a` to `b`. Longer
policies match the complete path exactly. This keeps common governance rules
compact while still allowing precise exceptions.

## Extension Points

The first release keeps the input format simple, but the core model is suitable
for later adapters:

- MoonBit AST or call-graph import.
- Architecture diagrams exported into `.mtf`.
- JSON or HTML report generation.
- Policy grouping by service, boundary, or repository.
- Severity profiles for local development and CI.
