# python123/moontrustflow

MoonTrustFlow is a lightweight data-flow security analysis framework for
MoonBit. It uses a compact `.mtf` rule language to model sensitive sources,
dangerous sinks, sanitizers, graph edges, and allowed paths, then reports
explainable taint-flow risks.

This is an independent MoonBit ecosystem project. It is designed for software
analysis, security review, AI-generated code governance, and trusted toolchain
experiments where a full static analyzer would be too large for a first
package.

## Capabilities

- Parse `.mtf` model text with line/column diagnostics.
- Declare `source`, `sink`, `sanitizer`, `node`, `edge`, and `allow`.
- Build a directed data-flow graph.
- Propagate taint from sensitive sources.
- Stop propagation through sanitizer nodes.
- Report complete source-to-sink risk paths.
- Suppress explicitly allowed safe paths.
- Generate stable text reports for CLI and CI usage.

## Example Model

```text
source user_input "external request body"
sanitizer escape_html "html escaping"
sink render_html "html response renderer"

edge user_input -> render_html "direct render"
edge user_input -> escape_html "sanitize"
edge escape_html -> render_html "safe render"

allow user_input -> escape_html -> render_html
```

The direct `user_input -> render_html` path is reported as a risk. The
sanitized path is stopped at `escape_html`, and the allowed path is documented
as an accepted safe flow.

## Public API

- `parse_model(input : String) -> Result[Model, TrustFlowError]`
- `analyze(model : Model) -> Array[Finding]`
- `format_finding(finding : Finding) -> String`
- `format_report(findings : Array[Finding]) -> String`
- `format_error(err : TrustFlowError) -> String`
- `node_kind_name(kind : NodeKind) -> String`

Core data types include `NodeKind`, `Node`, `Edge`, `Policy`, `Model`, and
`Finding`.

## CLI Demo

```bash
moon run cmd/main
```

Expected output shape:

```text
MoonTrustFlow demo
nodes=4, edges=4, findings=2
findings=2
[high] user_input -> render_html | path=user_input -> render_html | unsanitized flow reaches dangerous sink
[high] user_input -> sql_exec | path=user_input -> sql_exec | unsanitized flow reaches dangerous sink
```

## Development

```bash
moon info
moon fmt --check
moon test
moon run cmd/main
```

## Competition Materials

- `docs/competition/proposal.md`
- `docs/competition/acceptance-checklist.md`
- `docs/competition/submission-guide.md`
- `docs/competition/MoonTrustFlow项目申报书.pdf`

## License

Apache-2.0
