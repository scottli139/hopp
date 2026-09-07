import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../core/providers.dart';

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();

    try {
      final storage = _ref.read(storageServiceProvider);
      final settings = await storage.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    try {
      final storage = _ref.read(storageServiceProvider);
      await storage.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(themeMode: themeMode));
    }
  }

  Future<void> updateLanguage(String language) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(language: language));
    }
  }

  Future<void> updateEditorFontSize(double fontSize) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(editorFontSize: fontSize));
    }
  }

  /// 更新界面文字缩放（F5.7）
  Future<void> updateUiScale(double scale) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(uiScale: scale));
    }
  }

  Future<void> updateRequestTimeout(int timeoutMs) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(requestTimeoutMs: timeoutMs));
    }
  }

  Future<void> updateValidateCertificates(bool validate) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(validateCertificates: validate));
    }
  }

  Future<void> updateFollowRedirects(bool follow) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(followRedirects: follow));
    }
  }

  /// 更新 AI 配置（F9.5 连接参数；F9.9 增隐私门记录与 key 标志位）
  ///
  /// 注意：API Key 本体不走这里——F9.9 起存 ai_keys 加密 box，
  /// 由调用方（AI 设置对话框）直接经 StorageService.writeAiKey 写入，
  /// 此处只维护 [aiKeySavedPresets] 标志位。[aiApiKey] 参数仅历史兼容。
  Future<void> updateAiSettings({
    bool? aiEnabled,
    String? aiProviderPreset,
    String? aiBaseUrl,
    String? aiModel,
    String? aiApiKey,
    Map<String, bool>? aiCloudConsents,
    List<String>? aiKeySavedPresets,
    Map<String, String>? aiPresetBaseUrls,
  }) async {
    final current = state.value;
    if (current != null) {
      var settings = current;
      if (aiEnabled != null) {
        settings = settings.copyWith(aiEnabled: aiEnabled);
      }
      if (aiProviderPreset != null) {
        settings = settings.copyWith(aiProviderPreset: aiProviderPreset);
      }
      if (aiBaseUrl != null) {
        settings = settings.copyWith(aiBaseUrl: aiBaseUrl);
      }
      if (aiModel != null) {
        settings = settings.copyWith(aiModel: aiModel);
      }
      if (aiApiKey != null) {
        settings = settings.copyWith(aiApiKey: aiApiKey);
      }
      if (aiCloudConsents != null) {
        settings = settings.copyWith(aiCloudConsents: aiCloudConsents);
      }
      if (aiKeySavedPresets != null) {
        settings = settings.copyWith(aiKeySavedPresets: aiKeySavedPresets);
      }
      if (aiPresetBaseUrls != null) {
        settings = settings.copyWith(aiPresetBaseUrls: aiPresetBaseUrls);
      }
      await updateSettings(settings);
    }
  }

  /// 记录云端预设的隐私门确认（F9.9：按 Provider 记一次）
  Future<void> grantAiCloudConsent(String preset) async {
    final current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(
        aiCloudConsents: {...current.aiCloudConsents, preset: true},
      ));
    }
  }

  /// 清空全部云端隐私门确认记录（设置对话框「重置隐私确认」）
  Future<void> resetAiCloudConsents() async {
    final current = state.value;
    if (current != null && current.aiCloudConsents.isNotEmpty) {
      await updateSettings(current.copyWith(aiCloudConsents: const {}));
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return SettingsNotifier(ref);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);

  return settings.when(
    data: (s) {
      switch (s.themeMode) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    },
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});

final localeProvider = Provider<Locale?>((ref) {
  final settings = ref.watch(settingsProvider);

  return settings.when(
    data: (s) {
      switch (s.language) {
        case 'zh':
          return const Locale('zh');
        case 'en':
          return const Locale('en');
        default:
          // 'system'：返回 null 让 MaterialApp 跟随系统 locale
          return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 界面文字缩放（F5.7）：设置未加载/异常时回退 1.0（不缩放）
final uiScaleProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.uiScale ?? 1.0;
});
