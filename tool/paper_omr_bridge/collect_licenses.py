"""Collect original license texts from the actual sidecar build environment."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys


def collect(runtime: Path, output: Path) -> dict:
    runtime = runtime.resolve()
    distributions = sorted(runtime.glob("*.dist-info"))
    if not distributions:
        raise RuntimeError("Missing installed wheel metadata; build the sidecar first")
    for distribution in distributions:
        if not any(p.is_file() and p.name.upper().startswith(("LICENSE", "COPYING"))
                   for p in distribution.rglob("*")):
            raise RuntimeError(f"Missing license text: {distribution.name}")
    sources = [(p, Path("wheels") / p.relative_to(runtime))
               for p in sorted(runtime.rglob("*"))
               if p.is_file() and p.name.upper().startswith(("LICENSE", "COPYING", "NOTICE"))]
    python_license = Path(sys.base_prefix) / "LICENSE.txt"
    if not python_license.is_file():
        raise RuntimeError(f"Python license not found: {python_license}")
    sources.append((python_license, Path("python") / "LICENSE.txt"))
    records = []
    for source, relative in sources:
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        records.append({"path": relative.as_posix(),
                        "sha256": hashlib.sha256(destination.read_bytes()).hexdigest()})
    manifest = {"python": sys.version.split()[0],
                "distributions": [p.name for p in distributions], "files": records}
    (output / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    result = collect(args.runtime, args.output)
    print(f"Collected {len(result['files'])} license texts from {len(result['distributions'])} distributions and Python")
