"""把 lib/l10n/fragments/*.json 片段合并进 lib/l10n/app_zh.arb 与 app_en.arb。

用法：python tool/merge_l10n_fragments.py [--check]

规则：
- 片段名形如 pages_zh.json / pages_en.json，同名配对。
- zh 片段允许带 @key 元数据（占位符声明）；en 片段只放翻译。
- 键冲突且值不同时报错退出（不同值一律人工裁决，避免静默覆盖）。
- 主文件中已有键不再追加（幂等）；新增键追加到文件末尾，保持既有顺序。
- --check 只报告将要发生的变化与冲突，不写文件。
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N = ROOT / "lib" / "l10n"
FRAGMENTS = L10N / "fragments"


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def dump_arb(path: Path, data: dict) -> None:
    text = json.dumps(data, ensure_ascii=False, indent=2)
    path.write_text(text + "\n", encoding="utf-8")


def main() -> int:
    check_only = "--check" in sys.argv
    template_path = L10N / "app_zh.arb"
    english_path = L10N / "app_en.arb"
    template = load_json(template_path)
    english = load_json(english_path)

    pairs: dict[str, tuple[Path, Path]] = {}
    for zh_file in sorted(FRAGMENTS.glob("*_zh.json")):
        en_file = zh_file.with_name(zh_file.name[: -len("_zh.json")] + "_en.json")
        if not en_file.exists():
            print(f"[错误] 缺少配对英文片段：{en_file.name}")
            return 1
        scope = zh_file.name[: -len("_zh.json")]
        pairs[scope] = (zh_file, en_file)
    if not pairs:
        print("没有可合并的片段。")
        return 0

    conflicts: list[str] = []
    added_zh = 0
    added_en = 0
    for scope, (zh_file, en_file) in pairs.items():
        zh = load_json(zh_file)
        en = load_json(en_file)
        # @元数据（占位符声明）只存在于模板侧，不参与中英键对齐检查。
        zh_keys = {k for k in zh if not k.startswith("@")}
        en_keys = {k for k in en if not k.startswith("@")}
        if zh_keys != en_keys:
            only_zh = sorted(zh_keys - en_keys)
            only_en = sorted(en_keys - zh_keys)
            print(f"[错误] 片段 {scope} 中英键不一致 zh-only={only_zh} en-only={only_en}")
            return 1
        unknown_meta = sorted(k for k in zh if k.startswith("@") and k[1:] not in zh_keys)
        if unknown_meta:
            print(f"[错误] 片段 {scope} 存在无对应文案键的元数据：{unknown_meta}")
            return 1
        for key, value in zh.items():
            if key in template:
                if template[key] != value and not key.startswith("@"):
                    conflicts.append(f"{scope}.{key}: 主文件={template[key]!r} 片段={value!r}")
                continue
            template[key] = value
            if key.startswith("@"):
                continue
            added_zh += 1
        for key, value in en.items():
            if key in english:
                if english[key] != value and not key.startswith("@"):
                    conflicts.append(f"{scope}.{key}(en): 主文件={english[key]!r} 片段={value!r}")
                continue
            english[key] = value
            if key.startswith("@"):
                continue
            added_en += 1

    if conflicts:
        print("[错误] 片段与主文件存在值冲突，需人工裁决：")
        for item in conflicts:
            print("  -", item)
        return 1

    print(f"将新增 zh {added_zh} 条 / en {added_en} 条（含元数据）。")
    if check_only:
        return 0
    dump_arb(template_path, template)
    dump_arb(english_path, english)
    print("已写回 app_zh.arb / app_en.arb。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
