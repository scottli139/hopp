import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_theme_data.dart';

/// 应用统一卡片容器。
///
/// standard：底 surface、1px border 边、圆角 10；
/// elevated：底 background、shadowMd、圆角 10（浮层卡片）。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.padding = const EdgeInsets.all(AppMetrics.space16),
    this.onTap,
  });

  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppMetrics.space16),
    this.onTap,
  }) : elevated = true;

  final Widget child;
  final bool elevated;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: elevated ? t.background : t.surface,
        borderRadius: AppMetrics.br10,
        border: elevated ? null : Border.all(color: t.border),
        boxShadow: elevated ? AppShadows.md(context) : null,
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppMetrics.br10,
        child: card,
      ),
    );
  }
}
