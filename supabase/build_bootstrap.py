"""Combine committed migrations for a NEW Supabase project's SQL Editor."""
import argparse
from pathlib import Path


def build_sql() -> str:
    migrations = sorted((Path(__file__).resolve().parent / "migrations").glob("*.sql"))
    if not migrations:
        raise RuntimeError("No migrations found")
    parts = ["-- NEW project only; existing tables cause failure.", "BEGIN;"]
    for migration in migrations:
        parts.extend([f"-- BEGIN {migration.name}", migration.read_text(encoding="utf-8-sig")])
    return "\n".join(parts + ["COMMIT;", ""])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="New SQL file; never overwritten")
    args = parser.parse_args()
    sql = build_sql()
    with args.output.open("x", encoding="utf-8", newline="\n") as output:
        output.write(sql)
    print(f"Created {args.output}; review and run in a new project's SQL Editor.")
