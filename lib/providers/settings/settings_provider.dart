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

  /// 更新 AI 配置（F9.5：Tier 1 本地模型连接参数）
  Future<void> updateAiSettings({
    bool? aiEnabled,
    String? aiProviderPreset,
    String? aiBaseUrl,
    String? aiModel,
    String? aiApiKey,
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
      await updateSettings(settings);
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

final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);

  return settings.when(
    data: (s) {
      if (s.language == 'zh') {
        return const Locale('zh', 'CN');
      }
      return const Locale('en');
    },
    loading: () => const Locale('en'),
    error: (_, __) => const Locale('en'),
  );
});
