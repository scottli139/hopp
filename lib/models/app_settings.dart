import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
@HiveType(typeId: 4)
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @HiveField(0) @Default('system') String themeMode,
    @HiveField(1) @Default('en') String language,
    @HiveField(2) @Default(14) double editorFontSize,
    @HiveField(3) @Default('monospace') String editorFontFamily,
    @HiveField(4) @Default(true) bool validateCertificates,
    @HiveField(5) @Default(30000) int requestTimeoutMs,
    @HiveField(6) @Default(false) bool followRedirects,
    @HiveField(7) @Default(5) int maxRedirects,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  factory AppSettings.defaults() => const AppSettings();
}


