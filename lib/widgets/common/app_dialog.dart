import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import 'app_button.dart';
import 'app_divider.dart';

/// 应用统一对话框容器（规格见原型 .dialog）。
///
/// 规格：圆角 8、1px border 边、shadowMd、底 background；
/// 头部 padding 16/20/0、标题 16 w600、右侧关闭按钮；
/// 正文 padding 16/20、13px、textSecondary；
/// 底部按钮区右对齐、间距 8、padding 0/20/16。
///
/// 业务代码用 [showAppDialog] 弹出，底部按钮统一用 AppButton。
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.width = 420,
    this.height,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 16, 20, 16),
    this.showClose = true,
    this.showDividers = false,
    this.footerLeading,
  });

  final String title;
  final Widget child;

  /// 底部按钮（右对齐排布，间距 8）；null 时不渲染按钮区
  final List<Widget>? actions;

  /// 对话框宽度（默认 420）
  final double width;

  /// 固定高度（大型对话框如环境管理用）；null 时按内容自适应
  final double? height;

  /// 正文 padding（默认 16/20；大型对话框传 EdgeInsets.zero 自行布局）
  final EdgeInsetsGeometry contentPadding;

  /// 是否显示右上角关闭按钮
  final bool showClose;

  /// 头部下沿 / 底部上沿是否显示分隔细线（大型分区对话框用）
  final bool showDividers;

  /// 底部按钮区左侧内容（如用法提示），与右侧 actions 同一行
  final Widget? footerLeading;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Dialog(
      backgroundColor: t.background,
      surfaceTintColor: t.background,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppMetrics.space24),
      shape: const RoundedRectangleBorder(borderRadius: AppMetrics.br8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          // 必须有填充色：BoxShadow 绘制在填充之下，无填充时阴影会
          // 透过内部区域（整个对话框发灰）
          color: t.background,
          borderRadius: AppMetrics.br8,
          border: Border.all(color: t.border),
          boxShadow: AppShadows.md(context),
        ),
        child: ClipRRect(
          borderRadius: AppMetrics.br8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头部：标题 + 关闭
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppMetrics.space20,
                  AppMetrics.space16,
                  AppMetrics.space20,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.title16
                            .copyWith(color: t.textPrimary),
                      ),
                    ),
                    if (showClose)
                      AppIconButton(
                        icon: Icons.close,
                        tooltip: L10nBridge.t.common_close,
                        size: AppMetrics.height24,
                        iconSize: 14,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ),
              if (showDividers) ...[
                const SizedBox(height: AppMetrics.space16),
                const AppDivider(),
              ],
              // 正文
              Flexible(
                child: Padding(padding: contentPadding, child: child),
              ),
              // 底部按钮区
              if (actions != null) ...[
                if (showDividers) const AppDivider(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppMetrics.space20,
                    showDividers ? AppMetrics.space12 : 0,
                    AppMetrics.space20,
                    showDividers ? AppMetrics.space12 : AppMetrics.space16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (footerLeading != null) ...[
                        Expanded(child: footerLeading!),
                        const SizedBox(width: AppMetrics.space8),
                      ],
                      for (var i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppMetrics.space8),
                        actions![i],
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 弹出统一风格对话框。
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  double width = 420,
  double? height,
  EdgeInsetsGeometry? contentPadding,
  bool showClose = true,
  bool barrierDismissible = true,
}) {
  final dialog = AppDialog(
    title: title,
    actions: actions,
    width: width,
    height: height,
    contentPadding: contentPadding ?? const EdgeInsets.fromLTRB(20, 16, 20, 16),
    showClose: showClose,
    child: child,
  );
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => dialog,
  );
}
