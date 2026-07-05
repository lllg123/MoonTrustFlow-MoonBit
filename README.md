# MoonTrustFlow

MoonTrustFlow is a MoonBit Policy-as-Code toolkit for trusted data-flow
governance. It lets a team describe sensitive inputs, dangerous sinks, trust
boundaries, sanitizers, graph edges, and review exceptions in a compact `.mtf`
model, then produces deterministic findings that are easy to reuse in code
review, CI audit, and architecture governance workflows.

This project is intentionally narrow. It does not try to be a full compiler
frontend, a generic static-analysis framework, or a dependency scanner. The
current release focuses on the practical middle layer that many teams still
lack: a reviewable rule model for trusted-flow control that can be written by
humans today and connected to AST or call-graph adapters later.

## Why MoonTrustFlow

MoonBit already has strong language and package infrastructure, but the
ecosystem still needs small engineering-governance libraries that are easy to
embed into tools. MoonTrustFlow fills that gap with three priorities:

- Clear policy semantics that are small enough to audit.
- Deterministic output that is stable in CI and code review.
- A reusable core model that can grow into richer adapters and reports.

## Current Capabilities

- Parse `.mtf` policy models with stable line and column diagnostics.
- Declare `source`, `sink`, `sanitizer`, `boundary`, `node`, and `edge`.
- Express `deny`, `require`, and `allow` policies.
- Attach `severity=high|medium|low` to risk rules.
- Require a path to pass through a control point with `through=<node>`.
- Suppress reviewed exact paths with `allow`.
- Produce deterministic findings and text reports for CLI or CI use.

## Example Model

```text
source request_body "external input"
boundary api_gateway "trusted service boundary"
sanitizer escape_html "html output encoding"
sink render_html "html response renderer"

edge request_body -> api_gateway "ingress"
edge api_gateway -> render_html "response output"
edge api_gateway -> escape_html "encode"
edge escape_html -> render_html "safe render"

deny request_body -> render_html severity=high "raw input must not render directly"
require request_body -> render_html through=escape_html severity=medium "html output must be encoded"
allow request_body -> api_gateway -> escape_html -> render_html "encoded response path"
```

In this model, the path `request_body -> api_gateway -> render_html` violates
both the explicit `deny` policy and the `require` policy because it does not
pass through `escape_html`. The reviewed encoded path is listed as an exact
exception.

## Public API

- `parse_model(input : String) -> Result[Model, TrustFlowError]`
- `analyze(model : Model) -> Array[Finding]`
- `format_finding(finding : Finding) -> String`
- `format_report(findings : Array[Finding]) -> String`
- `format_error(err : TrustFlowError) -> String`
- `node_kind_name(kind : NodeKind) -> String`
- `rule_kind_name(kind : RuleKind) -> String`

Core data types include `NodeKind`, `RuleKind`, `Node`, `Edge`, `Policy`,
`Model`, and `Finding`.

## Quick Start

If you want to use the package from Mooncakes after publication:

```bash
moon add llgllg/moontrustflow
```

To explore the repository locally:

```bash
moon info
moon fmt --check
moon test
moon run cmd/main
```

## CLI Demo

```bash
moon run cmd/main
```

Expected output shape:

```text
MoonTrustFlow policy evaluation
nodes=4, edges=4, policies=3, findings=2
[high] deny violated: request_body -> api_gateway -> render_html | raw input must not render directly | suggestion=review or allow this path explicitly
[medium] require violated: request_body -> api_gateway -> render_html | html output must be encoded | suggestion=route this path through escape_html or add a reviewed exception
```

## Engineering Status

- Main implementation language: MoonBit
- License: Apache-2.0
- Local verification baseline: `moon info`, `moon fmt --check`, `moon test`,
  `moon run cmd/main`
- CI workflow: `.github/workflows/ci.yml`
- Package target: Mooncakes module `llgllg/moontrustflow`

## Competition Completion Notes

This repository was prepared as a public, verifiable MoonBit project for the
2026 MoonBit competition workflow. The organizer's public acceptance-facing
requirements checked on July 5, 2026 emphasize:

- Public repositories
- MoonBit as the primary implementation language
- A clear README
- Runnable examples
- CI and tests
- Publication on `mooncakes.io`

The current completion materials live under `docs/competition/` and focus on
evidence rather than proposal phrasing.

## Repository Links

- GitLink: <https://www.gitlink.org.cn/lllglllg/MoonTrustFlow>
- GitHub: <https://github.com/lllg123/MoonTrustFlow-MoonBit>

## Competition Materials

- `docs/competition/completion-report.md`
- `docs/competition/acceptance-checklist.md`
- `docs/competition/submission-guide.md`
- `docs/competition/proposal.md`
- `docs/competition/MoonTrustFlow项目申报书.pdf`

## License

Apache-2.0
