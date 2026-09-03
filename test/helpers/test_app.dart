import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hopp/l10n/generated/app_localizations.dart';

/// 测试统一壳：带 AppLocalizations 的 MaterialApp（F5.9）。
///
/// 业务 widget 经 `context.l10n` 取词后，裸 MaterialApp 会因缺少
/// AppLocalizations delegate 抛 null check——所有 widget 测试一律经此壳
/// 挂载。默认英文 locale：finder 用英文串断言，与界面语言解耦。
Widget hoppTestApp({
  required Widget home,
  Locale locale = const Locale('en'),
  ThemeData? theme,
  ThemeData? darkTheme,
  TextScaler? textScaler,
  bool debugShowCheckedModeBanner = false,
}) {
  return MaterialApp(
    locale: locale,
    theme: theme,
    darkTheme: darkTheme,
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    // textScaler 需注入到 Navigator 之上（showDialog 走根 Overlay，
    // 看不到 home 内的 MediaQuery），故经 builder 挂在顶层。
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
    home: home,
  );
}
