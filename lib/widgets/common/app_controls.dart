import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';

/// 应用统一开关（32×18，规格见原型 .switch）。
///
/// off：底 borderStrong；on：底 brand；滑块 14px 白色带 shadowSm，
/// 滑动动画 150ms。
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    Widget child = AnimatedContainer(
      duration: AppMetrics.animFast,
      width: 32,
      height: 18,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? t.brand : t.borderStrong,
        borderRadius: const BorderRadius.all(Radius.circular(9)),
      ),
      child: AnimatedAlign(
        duration: AppMetrics.animFast,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.onBrand,
            shape: BoxShape.circle,
            boxShadow: AppShadows.sm(context),
          ),
        ),
      ),
    );

    if (!_enabled) {
      child = Opacity(opacity: 0.45, child: child);
    }

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? () => onChanged!(!value) : null,
        child: child,
      ),
    );
  }
}

/// 应用统一勾选框（15×15，规格见原型 .checkbox）。
///
/// off：1.5px borderStrong 边、底 background；on：底 brand、白色对勾。
/// [label] 非空时右侧带 12px 文字（整行可点）。
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    Widget box = AnimatedContainer(
      duration: AppMetrics.animFast,
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: value ? t.brand : t.background,
        borderRadius: AppMetrics.br4,
        border: value ? null : Border.all(color: t.borderStrong, width: 1.5),
      ),
      child: value
          ? const Center(
              child: Icon(Icons.check, size: 11, color: AppColors.onBrand),
            )
          : null,
    );

    if (!_enabled) {
      box = Opacity(opacity: 0.45, child: box);
    }

    Widget child = box;
    if (label != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          const SizedBox(width: AppMetrics.space8),
          Flexible(
            child: Text(
              label!,
              style: AppTextStyles.caption12.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? () => onChanged!(!value) : null,
        child: child,
      ),
    );
  }
}
