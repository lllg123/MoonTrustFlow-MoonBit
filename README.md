# python123/moontrustflow

MoonTrustFlow is a lightweight data-flow security analysis framework for
MoonBit. It uses a small rule language to model sensitive sources, dangerous
sinks, sanitizers, graph edges, and allowed paths, then reports explainable
taint-flow risks.

The project is built as an independent MoonBit ecosystem entry. It does not
reuse the earlier MoonCSV or MoonLogLens repositories.

## Planned Capabilities

- Parse `.mtf` model text.
- Build a directed data-flow graph.
- Propagate taint from sensitive sources.
- Stop propagation through sanitizer nodes.
- Report complete source-to-sink risk paths.
- Suppress explicitly allowed safe paths.

## Development

```bash
moon test
moon run cmd/main
```

## License

Apache-2.0
