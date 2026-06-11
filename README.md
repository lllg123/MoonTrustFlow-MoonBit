# MoonTrustFlow

MoonTrustFlow is a lightweight Policy-as-Code toolkit for the MoonBit
ecosystem. It parses a compact `.mtf` model language, evaluates trusted data
flow policies, and produces deterministic reports that can be used in code
review, CI audit, and architecture governance workflows.

The project focuses on a practical middle layer: teams can describe sources,
sinks, trust boundaries, sanitizers, graph edges, deny rules, required control
points, and reviewed exceptions without depending on a full language frontend in
the first version.

## Why This Project

MoonBit already has strong language and package infrastructure, but the
ecosystem still needs small engineering-governance libraries that are easy to
embed into tools. MoonTrustFlow fills that space with a rule model that is
simple enough to test thoroughly and general enough to grow toward source-code
adapters, call graphs, and richer compliance output.

## Capabilities

- Parse `.mtf` policy models with stable line/column diagnostics.
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
both the explicit `deny` policy and the `require` policy because it does not pass
through `escape_html`. The reviewed encoded path is listed as an exact
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

## Development

```bash
moon info
moon fmt --check
moon test
moon run cmd/main
```

## Repository Links

- GitLink: <https://www.gitlink.org.cn/lllglllg/MoonTrustFlow>
- GitHub: <https://github.com/lllg123/MoonTrustFlow-MoonBit->

## Competition Materials

- `docs/competition/proposal.md`
- `docs/competition/acceptance-checklist.md`
- `docs/competition/submission-guide.md`
- `docs/competition/MoonTrustFlow项目申报书.pdf`

## License

Apache-2.0
