from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "fixtures" / "benchmarks" / "manifest.json"


def run_fixture(path: Path) -> dict[str, int]:
    env = os.environ.copy()
    env["MOONTRUSTFLOW_MODEL_TEXT"] = path.read_text(encoding="utf-8")
    env["MOONTRUSTFLOW_SOURCE_LABEL"] = str(path)
    result = subprocess.run(
        ["moon", "-C", str(ROOT), "run", "cmd/main", "--", "--json"],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        env=env,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"{path}: moon run failed with exit code {result.returncode}:\n"
            f"{result.stderr}"
        )
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"{path}: CLI did not emit valid JSON: {error}") from error
    summary = payload.get("summary")
    if not isinstance(summary, dict):
        raise RuntimeError(f"{path}: JSON output has no summary object")
    return {
        key: int(summary[key])
        for key in ("node_count", "edge_count", "policy_count", "finding_count")
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run every deterministic MoonTrustFlow benchmark fixture."
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST,
        help="Fixture manifest path (default: fixtures/benchmarks/manifest.json)",
    )
    args = parser.parse_args()
    manifest_path = args.manifest if args.manifest.is_absolute() else ROOT / args.manifest
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    failures: list[str] = []

    for item in manifest["fixtures"]:
        fixture_path = ROOT / item["path"]
        expected = item["expected"]
        try:
            actual = run_fixture(fixture_path)
        except (OSError, RuntimeError, KeyError, ValueError) as error:
            failures.append(str(error))
            print(f"[FAIL] {item['path']}: {error}")
            continue
        if actual != expected:
            failures.append(
                f"{item['path']}: expected {expected}, got {actual}"
            )
            print(f"[FAIL] {item['path']}: expected {expected}, got {actual}")
        else:
            print(f"[PASS] {item['path']}: {actual}")

    if failures:
        raise SystemExit(
            "Fixture corpus verification failed:\n- " + "\n- ".join(failures)
        )
    print(f"Fixture corpus passed: {len(manifest['fixtures'])} fixtures")


if __name__ == "__main__":
    main()
