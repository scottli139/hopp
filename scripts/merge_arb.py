#!/usr/bin/env python3
"""把 l10n 片段合并进 app_en.arb / app_zh.arb（F5.9 并行抽取的串行化入口）。

用法：python3 scripts/merge_arb.py <fragment.json>
片段格式：{"en": {"key": "..."}, "zh": {"key": "..."}}
行为：新 key 追加到文件尾部；已存在的 key 若值不同则报错退出（防并行覆盖）。
调用方必须用 flock 串行化：
  flock /tmp/hopp_arb.lock python3 scripts/merge_arb.py lib/l10n/pending/xxx.json
"""
import json
import os
import subprocess
import sys
from collections import OrderedDict


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f, object_pairs_hook=OrderedDict)


def save(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main():
    frag_path = sys.argv[1]
    with open(frag_path, encoding="utf-8") as f:
        frag = json.load(f)

    conflicts = []
    for lang, arb_path in (
        ("en", "lib/l10n/app_en.arb"),
        ("zh", "lib/l10n/app_zh.arb"),
    ):
        arb = load(arb_path)
        for key, value in frag.get(lang, {}).items():
            if key in arb and arb[key] != value:
                conflicts.append(f"{lang}:{key!r} existing={arb[key]!r} new={value!r}")
            elif key not in arb:
                arb[key] = value
        save(arb_path, arb)

    # 双向校验：两个 ARB 的 key 集合必须一致
    en_keys = set(load("lib/l10n/app_en.arb"))
    zh_keys = set(load("lib/l10n/app_zh.arb"))
    missing = (en_keys - zh_keys) | (zh_keys - en_keys)
    if missing:
        conflicts.append(f"key 集合不一致: {sorted(missing)}")

    if conflicts:
        print("CONFLICTS:")
        for c in conflicts:
            print(" ", c)
        sys.exit(1)
    print(f"OK: merged {sum(len(v) for v in frag.values())} keys from {frag_path}")

    # merge 成功后重新生成纯 Dart 本地化核心（lib/l10n/generated/l10n_core.g.dart）
    gen_script = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              "gen_l10n_core.py")
    subprocess.run([sys.executable, gen_script], check=True)


if __name__ == "__main__":
    main()
