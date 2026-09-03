#!/usr/bin/env python3
"""从 app_en.arb / app_zh.arb 生成纯 Dart 本地化核心（F5.9 / M8.8）。

产物：lib/l10n/generated/l10n_core.g.dart —— 只依赖 dart 核心库，
禁止 import 任何 flutter 包，供 CLI（dart compile exe）与不依赖
Flutter 的 service（http_service / assertion_engine 等）共用。
GUI 侧取词仍走 AppLocalizations（context.l10n / L10nBridge），
locale 由 L10nBridge.update 同步进 L10nCore.locale。

用法：python3 scripts/gen_l10n_core.py（通常由 merge_arb.py 自动调用）
"""
import json
import os
from collections import OrderedDict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EN_ARB = os.path.join(ROOT, "lib", "l10n", "app_en.arb")
ZH_ARB = os.path.join(ROOT, "lib", "l10n", "app_zh.arb")
OUT = os.path.join(ROOT, "lib", "l10n", "generated", "l10n_core.g.dart")

HEADER = """// GENERATED — 由 scripts/gen_l10n_core.py 从 ARB 生成，勿手改
//
// 纯 Dart 本地化核心（F5.9）：仅供 CLI 与不依赖 Flutter 的 service 使用，
// 禁止 import 任何 flutter 包（dart 核心库 only）。
// GUI 侧取词走 AppLocalizations（context.l10n / L10nBridge），
// 生效 locale 由 L10nBridge.update 同步到 [L10nCore.locale]。

class L10nCore {
  L10nCore._();

  /// 当前语言（如 'en' / 'zh'）。默认英文：CLI 不做设置即维持英文输出。
  static String locale = 'en';

  /// 取词：按 [locale] 取表（zh 前缀命中中文表，否则英文表）；
  /// key 缺失时回退英文表，再缺失返回 key 本身；
  /// `{name}` 占位符用 [params] 替换。
  static String t(String key, [Map<String, String>? params]) {
    final table = locale.startsWith('zh') ? _zh : _en;
    var value = table[key] ?? _en[key] ?? key;
    if (params != null) {
      params.forEach((name, paramValue) {
        value = value.replaceAll('{$name}', paramValue);
      });
    }
    return value;
  }
"""


def load(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f, object_pairs_hook=OrderedDict)
    # 跳过 @metadata 条目
    return OrderedDict((k, v) for k, v in data.items() if not k.startswith("@"))


def dart_str(s):
    # json.dumps 产出的转义（\\n / \\" / \\uXXXX，含 emoji 代理对）在
    # Dart 双引号字符串中均合法；只需额外转义 Dart 插值触发符 $
    return json.dumps(s, ensure_ascii=True).replace("$", "\\$")


def emit_table(name, table):
    lines = [f"  static const Map<String, String> {name} = {{"]
    for key, value in table.items():
        lines.append(f"    {dart_str(key)}: {dart_str(value)},")
    lines.append("  };")
    return "\n".join(lines)


def main():
    en = load(EN_ARB)
    zh = load(ZH_ARB)

    content = (
        HEADER
        + "\n"
        + emit_table("_en", en)
        + "\n\n"
        + emit_table("_zh", zh)
        + "\n}\n"
    )
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"OK: generated {OUT} ({len(en)} en keys, {len(zh)} zh keys)")


if __name__ == "__main__":
    main()
