# MoonTrustFlow

MoonTrustFlow is a MoonBit Policy-as-Code toolkit for trusted data-flow
governance. It turns a compact `.mtf` rule file into deterministic findings
that can be reused in code review, CI audit, architecture governance, and
security acceptance work.

This project is intentionally scoped as the policy and path-analysis middle
layer. It does not claim to be a full compiler frontend or a production-ready
whole-program analyzer. Instead, it focuses on the part many MoonBit projects
still lack today: a small, reviewable, explainable trust-flow engine that can
later accept AST, call-graph, or architecture-adapter inputs.

## Why It Matters

- MoonBit ecosystem projects need reusable governance tooling, not only runtime libraries.
- Security and compliance reviews often need deterministic source-to-sink evidence instead of prose.
- A compact rule language is easier to audit, version, and discuss in pull requests than ad hoc scripts.

## Current Capabilities

- Parse `.mtf` models with stable line and column diagnostics.
- Model `source`, `sink`, `sanitizer`, `boundary`, `node`, and `edge`.
- Evaluate `deny`, `require through=`, and exact-path `allow` policies.
- Report complex scenarios including multi-sink, branching, and cycle-pruned paths.
- Emit both plain-text and JSON findings.
- Drive real fixture analysis through repository scripts without changing the core package target surface.

## Public API

- `parse_model(input : String) -> Result[Model, TrustFlowError]`
- `analyze(model : Model) -> Array[Finding]`
- `format_finding(finding : Finding) -> String`
- `format_report(findings : Array[Finding]) -> String`
- `format_report_json(findings : Array[Finding]) -> String`
- `format_error(err : TrustFlowError) -> String`

Core public types include `NodeKind`, `RuleKind`, `Node`, `Edge`, `Policy`,
`Model`, `Finding`, and `TrustFlowError`.

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

## Quick Start

Install the package from Mooncakes:

```bash
moon add llgllg/moontrustflow
```

Validate the repository locally:

```bash
moon check --target all
moon test
moon fmt
moon info
moon run cmd/main
```

Analyze a real `.mtf` fixture through the repository wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\analyze_model.ps1 -Path fixtures\models\webapp_taint.mtf -Json
```

The wrapper reads the file, exports `MOONTRUSTFLOW_MODEL_TEXT`, and then reuses
`moon run cmd/main` for deterministic JSON or text output.

## CLI Behavior

`moon run cmd/main` always works with the embedded sample model.

```text
MoonTrustFlow policy evaluation
source=embedded-sample
nodes=4, edges=4, policies=3, findings=2
```

Add `--json` or `-j` to emit structured output:

```bash
moon run cmd/main -- --json
```

For real files, use the wrapper script shown above. This keeps the core package
cross-target friendly while still providing a practical repository CLI for
actual `.mtf` inputs.

## Engineering Status

- Main implementation language: MoonBit
- License: Apache-2.0
- Tracked MoonBit source/interface scale on 2026-07-10: about `1026` lines across `.mbt` and `.mbti`
- Fixture coverage includes branching, cycle-pruning, multi-sink, and reviewed-exception scenarios
- Mooncakes module: `llgllg/moontrustflow`
- CI workflow: `.github/workflows/ci.yml`

## OSC2026 Notes

The official OSC2026 site checked on **2026-07-10** shows:

- proposal and development window through **2026-07-12**
- acceptance window **2026-07-13** to **2026-07-17**
- a reference project scale signal of about **4~10k LOC**
- emphasis on public development traces, clear documentation, runnable tests,
  maintainability, and ecosystem value

MoonTrustFlow is still below that reference LOC band, so this repository now
responds by making the implemented scope more concrete:

- split MoonBit modules instead of one large file
- richer fixtures and edge-case tests
- JSON output in addition to text output
- contributor identity and acceptance self-check scripts
- CI aligned to the MoonBit 0.10.3-compatible command set

Important toolchain note: on the current MoonBit 0.10.3 CLI, `moon fmt
--deny-warn` and `moon info --deny-warn` are not accepted commands. This repo
therefore uses the community-compatible validation pattern:

- `moon fmt` + `git diff --exit-code`
- `moon info` + `git diff --exit-code`

## Repository Links

- GitLink: <https://www.gitlink.org.cn/lllglllg/MoonTrustFlow>
- GitHub: <https://github.com/lllg123/MoonTrustFlow-MoonBit>
- Mooncakes: <https://mooncakes.io/modules/llgllg/moontrustflow>

## Competition Materials

- [Acceptance Checklist](docs/competition/acceptance-checklist.md)
- [Completion Report](docs/competition/completion-report.md)
- [Source Attribution](docs/competition/source-attribution.md)
- [Submission Guide](docs/competition/submission-guide.md)
- [Proposal Archive](docs/competition/proposal.md)
- [Proposal PDF](docs/competition/MoonTrustFlow项目申报书.pdf)

## License

Apache-2.0
