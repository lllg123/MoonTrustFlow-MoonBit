from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analyze a real .mtf file with the MoonTrustFlow CLI."
    )
    parser.add_argument("path", help="Path to the .mtf model file")
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON output",
    )
    args = parser.parse_args()

    target = Path(args.path).resolve()
    env = os.environ.copy()
    env["MOONTRUSTFLOW_MODEL_TEXT"] = target.read_text(encoding="utf-8")
    env["MOONTRUSTFLOW_SOURCE_LABEL"] = str(target)

    command = ["moon", "-C", str(ROOT), "run", "cmd/main"]
    if args.json:
        command.extend(["--", "--json"])
    subprocess.run(command, check=True, env=env)


if __name__ == "__main__":
    main()
