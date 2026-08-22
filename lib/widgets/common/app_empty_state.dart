import 'package:flutter/material.dart';

import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 统一空态：图标底块 + 标题 + 可选副标题 + 可选操作按钮。
///
/// 用于侧栏 / 请求编辑区 / 响应区等「无内容」场景，避免各处手写
/// 颜色与间距不一致。图标固定 28px（56px surfaceVariant 圆角底块），
/// 标题 body13 w600 textSecondary，副标题 caption12 textTertiary。
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// 可选操作按钮（如「Create Collection」）
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: t.surfaceVariant,
                borderRadius: AppMetrics.br10,
              ),
              child: Icon(icon, size: 28, color: t.textTertiary),
            ),
            const SizedBox(height: AppMetrics.space16),
            Text(
              title,
              style: AppTextStyles.body13.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppMetrics.space4),
              Text(
                subtitle!,
                style: AppTextStyles.caption12.copyWith(
                  color: t.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppMetrics.space16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
