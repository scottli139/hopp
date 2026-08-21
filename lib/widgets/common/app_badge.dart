import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// HTTP 方法徽章：方法色文字 + 方法色 soft 底（亮 10% / 暗 14%）。
///
/// 规格：高 18、水平 padding 5、圆角 4、micro10（10px w700）、最小宽 34。
/// 用于侧栏请求列表等需要方法标识的场景。
class MethodBadge extends StatelessWidget {
  const MethodBadge(this.method, {super.key});

  final String method;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.method(method);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        borderRadius: AppMetrics.br4,
      ),
      alignment: Alignment.center,
      child: Text(
        method.toUpperCase(),
        style: AppTextStyles.micro10.copyWith(color: color),
      ),
    );
  }
}

/// 状态码徽章：状态码色文字 + 语义 soft 底（随亮/暗主题）。
///
/// 规格：高 22、水平 padding 8、圆角 4、11px w600。
class StatusChip extends StatelessWidget {
  const StatusChip(this.statusCode, {super.key, this.label});

  final int? statusCode;

  /// 显示文本，默认 `'$statusCode'`，如「200 OK」可显式传入
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final color = AppColors.statusCode(statusCode);
    final code = statusCode;
    final soft = code == null
        ? t.surfaceVariant
        : code >= 400
            ? t.errorSoft
            : code >= 300
                ? t.warningSoft
                : code >= 200
                    ? t.successSoft
                    : t.surfaceVariant;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: AppMetrics.br4,
      ),
      alignment: Alignment.center,
      child: Text(
        label ?? '$statusCode',
        style: AppTextStyles.tiny11.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
