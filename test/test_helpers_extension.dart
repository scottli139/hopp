/// WidgetTester 扩展
/// 
/// 提供额外的测试辅助方法
/// 仅在测试中使用

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtension on WidgetTester {
  /// 等待条件满足
  /// 
  /// 持续 pump 直到条件满足或超时
  Future<bool> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pumpInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      await pump(pumpInterval);

      if (any(finder)) {
        return true;
      }
    }

    return false;
  }

  /// 等待文本出现
  Future<bool> waitForText(
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return waitFor(find.text(text), timeout: timeout);
  }

  /// 安全地输入文本
  /// 
  /// 先确保字段有焦点，然后输入文本
  Future<void> enterTextSafely(Finder finder, String text) async {
    // 确保 Widget 存在
    expect(finder, findsOneWidget);

    // 点击获取焦点
    await tap(finder);
    await pump();

    // 输入文本
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// 拖动直到找到目标
  Future<bool> dragUntilVisible(
    Finder target,
    Finder scrollable,
    Offset moveStep, {
    int maxIterations = 100,
  }) async {
    for (var i = 0; i < maxIterations; i++) {
      if (any(target)) {
        return true;
      }

      await drag(scrollable, moveStep);
      await pumpAndSettle();
    }

    return false;
  }
}
