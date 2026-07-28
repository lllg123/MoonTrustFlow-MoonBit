from __future__ import annotations

import argparse
import json
from pathlib import Path


VALID_KINDS = {"source", "sink", "sanitizer", "boundary", "node"}
VALID_RULES = {"allow", "deny", "require"}


def render_node(node: dict[str, object]) -> str:
    kind = str(node["kind"])
    if kind not in VALID_KINDS:
        raise ValueError(f"unsupported node kind: {kind}")
    name = str(node["name"])
    description = str(node.get("description", ""))
    return f'{kind} {name} "{description}"'


def render_edge(edge: dict[str, object]) -> str:
    label = str(edge.get("label", ""))
    return f'edge {edge["from"]} -> {edge["to"]} "{label}"'


def render_policy(policy: dict[str, object]) -> str:
    kind = str(policy["kind"])
    if kind not in VALID_RULES:
        raise ValueError(f"unsupported policy kind: {kind}")
    path = policy["path"]
    if not isinstance(path, list) or len(path) < 2:
        raise ValueError(f"policy path must contain at least two nodes: {policy}")
    path_text = " -> ".join(str(item) for item in path)
    parts = [kind, path_text]
    through = policy.get("through")
    severity = policy.get("severity")
    description = str(policy.get("description", ""))
    if through:
        parts.append(f"through={through}")
    if severity:
        parts.append(f"severity={severity}")
    if description:
        parts.append(f'"{description}"')
    return " ".join(parts)


def render_model(payload: dict[str, object]) -> str:
    nodes = payload.get("nodes", [])
    edges = payload.get("edges", [])
    policies = payload.get("policies", [])
    lines: list[str] = []
    for node in nodes:
        lines.append(render_node(node))
    for edge in edges:
        lines.append(render_edge(edge))
    for policy in policies:
        lines.append(render_policy(policy))
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert a simple call-graph JSON description into .mtf."
    )
    parser.add_argument("input", help="Path to the JSON call graph file")
    parser.add_argument(
        "-o",
        "--output",
        help="Where to write the generated .mtf file. Defaults next to the input.",
    )
    args = parser.parse_args()

    source_path = Path(args.input).resolve()
    payload = json.loads(source_path.read_text(encoding="utf-8"))
    rendered = render_model(payload)

    if args.output:
        output_path = Path(args.output).resolve()
    else:
        output_path = source_path.with_suffix(".mtf")
    output_path.write_text(rendered, encoding="utf-8")
    print(output_path)


if __name__ == "__main__":
    main()
