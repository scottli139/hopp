import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/theme/app_text_styles.dart';

void main() {
  group('AppTextStyles 代码字体（2026-09-08 响应体字号根因）', () {
    // Menlo 在 Windows/Linux 缺失，回退链末端命中 Microsoft YaHei，
    // 异步解析导致 CodeField 字形在重绘后放大约 1.5 倍；
    // 内置 JetBrains Mono 后首选必中，回退链仅兜底
    test('code12/code11 首选内置 JetBrainsMono，回退链含系统 mono', () {
      expect(AppTextStyles.code12.fontFamily, 'JetBrainsMono');
      expect(AppTextStyles.code11.fontFamily, 'JetBrainsMono');
      expect(AppTextStyles.code12.fontFamilyFallback, contains('Menlo'));
      expect(AppTextStyles.code12.fontFamilyFallback, contains('Consolas'));
      expect(AppTextStyles.code11.fontFamilyFallback, contains('Menlo'));
      expect(AppTextStyles.code11.fontFamilyFallback, contains('Consolas'));
    });
  });
}
