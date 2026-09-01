import 'package:flutter_test/flutter_test.dart';
import 'package:hopp/utils/epoch_annotation.dart';

void main() {
  group('EpochAnnotation.format', () {
    test('13 位毫秒格式化为本地可读时间', () {
      final millis = DateTime(2024, 3, 10, 15, 42, 33).millisecondsSinceEpoch;
      final result = EpochAnnotation.format('$millis');
      expect(result, isNotNull);
      expect(result, startsWith('→ 2024-03-10 15:42:33'));
    });

    test('10 位秒按 ×1000 解析', () {
      final seconds =
          DateTime(2024, 3, 10, 15, 42, 33).millisecondsSinceEpoch ~/ 1000;
      final result = EpochAnnotation.format('$seconds');
      expect(result, startsWith('→ 2024-03-10 15:42:33'));
    });

    test('范围外返回 null：过小 / 过大 / 负数 / 非数字', () {
      expect(EpochAnnotation.format('999999999'), isNull); // 9 位
      expect(EpochAnnotation.format('999999999999999'), isNull); // 15 位超 9999 年
      expect(EpochAnnotation.format('-1564761599000'), isNull);
      expect(EpochAnnotation.format('abc'), isNull);
      expect(EpochAnnotation.format('1.5'), isNull);
    });

    test('10 位纯数字 id 不误判（用户实测：3365948418 → 2076 年）', () {
      expect(EpochAnnotation.format('3365948418'), isNull);
    });

    test('秒级 near-now 边界：现在 ± 范围内可标注，超 +5 年缓冲拒绝', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(EpochAnnotation.format('${nowSec - 100000}'), isNotNull); // 约 1 天前
      expect(EpochAnnotation.format('${nowSec + 86400 * 300}'),
          isNotNull); // 约 300 天后
      expect(EpochAnnotation.format('${nowSec + 86400 * 366 * 10}'),
          isNull); // 10 年后
    });
  });

  group('EpochAnnotation.scanLine', () {
    test('JSON 数值 token 标为 epoch 分段', () {
      final segments = EpochAnnotation.scanLine('"startTime": 1564156800000,');
      final epochs = segments.where((s) => s.isEpoch).toList();
      expect(epochs, hasLength(1));
      expect(epochs.single.text, '1564156800000');
    });

    test('字符串字面量内的数字不标注（含转义引号）', () {
      final segments = EpochAnnotation.scanLine(r'"orderNo": "1564761599000",');
      expect(segments.any((s) => s.isEpoch), isFalse);
      // 原文保留
      expect(
        segments.map((s) => s.text).join(),
        r'"orderNo": "1564761599000",',
      );
    });

    test('字符串内转义引号不误判为字符串结束', () {
      final segments = EpochAnnotation.scanLine(r'"a\": 1564761599000');
      expect(segments.any((s) => s.isEpoch), isFalse);
    });

    test('一行多个 epoch 各自分段，普通数字不标注', () {
      final segments =
          EpochAnnotation.scanLine('[1564156800000, 3600, 1564761599000]');
      final epochs = segments.where((s) => s.isEpoch).map((s) => s.text);
      expect(epochs, ['1564156800000', '1564761599000']);
    });

    test('负数数字串不标注', () {
      final segments = EpochAnnotation.scanLine('[-1564761599000]');
      expect(segments.any((s) => s.isEpoch), isFalse);
    });
  });

  group('EpochAnnotation.annotateLine', () {
    test('命中行追加注释，无命中行原样返回', () {
      final hit = EpochAnnotation.annotateLine('  "startTime": 1564156800000,');
      expect(hit, contains('→ 20'));
      expect(
        EpochAnnotation.annotateLine('  "duration": 3600,'),
        '  "duration": 3600,',
      );
    });
  });
}
