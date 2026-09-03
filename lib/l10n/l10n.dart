import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';
import 'generated/l10n_core.g.dart';

/// BuildContext 快捷取词：`context.l10n.xxx`（F5.9 / M8.8）
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// 无 BuildContext 场景（services / providers / models 的用户可见消息）取词桥。
///
/// 应用同一时刻只有一个生效 locale，由 `MaterialApp.builder` 在每次构建时
/// 调用 [L10nBridge.update] 刷新；未初始化（单元测试不挂界面等）回退英文。
// ignore: avoid_classes_with_only_static_members
class L10nBridge {
  static AppLocalizations _current = AppLocalizationsEn();

  static void update(AppLocalizations l10n) {
    _current = l10n;
    // 同步纯 Dart 核心（CLI / service 共用）的生效 locale
    L10nCore.locale = l10n.localeName;
  }

  /// 当前语言的取词入口：`L10nBridge.t.error_requestFailed`
  static AppLocalizations get t => _current;
}
