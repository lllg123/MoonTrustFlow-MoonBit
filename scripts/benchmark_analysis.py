from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def build_chain_model(hops: int) -> str:
    lines = ['source request_body "external input"']
    for index in range(1, hops + 1):
        lines.append(f'node hop_{index:03d} "generated hop"')
    lines.append('sink audit_sink "final sink"')
    lines.append('edge request_body -> hop_001 "ingress"')
    for index in range(1, hops):
        lines.append(
            f'edge hop_{index:03d} -> hop_{index + 1:03d} "generated edge"'
        )
    lines.append(f'edge hop_{hops:03d} -> audit_sink "egress"')
    lines.append(
        'deny request_body -> audit_sink severity=medium "generated stress path"'
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a large linear model and benchmark MoonTrustFlow analysis."
    )
    parser.add_argument("--hops", type=int, default=250, help="Number of intermediate nodes")
    args = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="moontrustflow-bench-") as tmp:
        model_path = Path(tmp) / "stress_chain.mtf"
        model_path.write_text(build_chain_model(args.hops), encoding="utf-8")

        started = time.perf_counter()
        env = os.environ.copy()
        env["MOONTRUSTFLOW_MODEL_TEXT"] = model_path.read_text(encoding="utf-8")
        env["MOONTRUSTFLOW_SOURCE_LABEL"] = str(model_path)
        result = subprocess.run(
            ["moon", "-C", str(ROOT), "run", "cmd/main", "--", "--json"],
            check=True,
            capture_output=True,
            text=True,
            env=env,
        )
        elapsed_ms = (time.perf_counter() - started) * 1000.0
        payload = json.loads(result.stdout)
        summary = payload["summary"]
        print(json.dumps(
            {
                "input": str(model_path),
                "hops": args.hops,
                "elapsed_ms": round(elapsed_ms, 2),
                "summary": summary,
            },
            indent=2,
        ))


if __name__ == "__main__":
    main()
