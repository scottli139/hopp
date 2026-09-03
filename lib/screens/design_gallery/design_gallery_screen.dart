import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_syntax_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_data.dart';
import '../../widgets/common/app_badge.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_controls.dart';
import '../../widgets/common/app_divider.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_popup_menu.dart';
import '../../widgets/common/app_tabs.dart';
import '../../widgets/common/app_text_field.dart';

/// 设计 Gallery：单页展示全部设计 token 与统一组件的亮/暗双主题效果。
///
/// 上半区为 Light 主题、下半区为 Dark 主题，两区分别用
/// `Theme(data: AppTheme.light())` / `Theme(data: AppTheme.dark())` 包裹，
/// 与应用全局主题无关。通过 test-mode 指令 `open_design_gallery` 打开
/// （见 ui_test_mode.dart），用于设计走查与设计系统重构回归对照。
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.gallery_title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GalleryThemePane(
              theme: AppTheme.light(),
              title: context.l10n.settings_themeLight,
            ),
            _GalleryThemePane(
              theme: AppTheme.dark(),
              title: context.l10n.settings_themeDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// 单主题展示区：套上一层独立 Theme，内部按小节竖排。
class _GalleryThemePane extends StatelessWidget {
  const _GalleryThemePane({required this.theme, required this.title});

  final ThemeData theme;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final t = context.appTheme;
          return Container(
            color: t.background,
            padding: const EdgeInsets.all(AppMetrics.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.gallery_themeTitle(title),
                  style: AppTextStyles.display20.copyWith(
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: AppMetrics.space24),
                const _ColorsSection(),
                const SizedBox(height: AppMetrics.space32),
                const _TypographySection(),
                const SizedBox(height: AppMetrics.space32),
                const _MetricsSection(),
                const SizedBox(height: AppMetrics.space32),
                const _ShadowsSection(),
                const SizedBox(height: AppMetrics.space32),
                const _ComponentsSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 小节标题（Colors / Typography / ...）
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.title16.copyWith(
        color: context.appTheme.textPrimary,
      ),
    );
  }
}

/// 小节内的分组标注（如 AppThemeData / AppColors / AppSyntaxColors）
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.tiny11.copyWith(
        color: context.appTheme.textTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 控件 + 名称的横向小组合（开关 / 勾选框演示用）
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: AppMetrics.space8),
        Text(
          label,
          style: AppTextStyles.caption12.copyWith(
            color: context.appTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 颜色的 8 位 ARGB hex 字符串（如 #FF6366F1），运行时计算。
String _hexColor(Color color) {
  int channel(double v) => (v * 255.0).round() & 0xff;
  final argb = channel(color.a) << 24 |
      channel(color.r) << 16 |
      channel(color.g) << 8 |
      channel(color.b);
  return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

// ========== Colors ==========

class _ColorsSection extends StatelessWidget {
  const _ColorsSection();

  static const _paletteColors = <(String, Color)>[
    ('brand', AppColors.brand),
    ('brandLight', AppColors.brandLight),
    ('brandDark', AppColors.brandDark),
    ('onBrand', AppColors.onBrand),
    ('black', AppColors.black),
    ('transparent', AppColors.transparent),
    ('success', AppColors.success),
    ('warning', AppColors.warning),
    ('error', AppColors.error),
    ('info', AppColors.info),
    ('errorStrong', AppColors.errorStrong),
    ('accentPink', AppColors.accentPink),
    ('methodGet', AppColors.methodGet),
    ('methodPost', AppColors.methodPost),
    ('methodPut', AppColors.methodPut),
    ('methodDelete', AppColors.methodDelete),
    ('methodPatch', AppColors.methodPatch),
    ('methodOther', AppColors.methodOther),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeColors = <(String, Color)>[
      ('background', t.background),
      ('surface', t.surface),
      ('surfaceVariant', t.surfaceVariant),
      ('border', t.border),
      ('borderStrong', t.borderStrong),
      ('textPrimary', t.textPrimary),
      ('textSecondary', t.textSecondary),
      ('textTertiary', t.textTertiary),
      ('brand', t.brand),
      ('brandHover', t.brandHover),
      ('brandSoft', t.brandSoft),
      ('success', t.success),
      ('successSoft', t.successSoft),
      ('warning', t.warning),
      ('warningSoft', t.warningSoft),
      ('error', t.error),
      ('errorSoft', t.errorSoft),
      ('info', t.info),
      ('infoSoft', t.infoSoft),
    ];

    final syntaxColors = <(String, Color)>[
      ('key', AppSyntaxColors.getKey(isDark)),
      ('string', AppSyntaxColors.getString(isDark)),
      ('number', AppSyntaxColors.getNumber(isDark)),
      ('keyword', AppSyntaxColors.getKeyword(isDark)),
      ('punctuation', AppSyntaxColors.getPunctuation(isDark)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(context.l10n.gallery_colors),
        const SizedBox(height: AppMetrics.space16),
        _GroupLabel(context.l10n.gallery_groupThemeData),
        const SizedBox(height: AppMetrics.space8),
        _SwatchWrap(entries: themeColors),
        const SizedBox(height: AppMetrics.space16),
        _GroupLabel(context.l10n.gallery_groupAppColors),
        const SizedBox(height: AppMetrics.space8),
        const _SwatchWrap(entries: _paletteColors),
        const SizedBox(height: AppMetrics.space16),
        _GroupLabel(context.l10n.gallery_groupSyntaxColors),
        const SizedBox(height: AppMetrics.space8),
        _SwatchWrap(entries: syntaxColors),
      ],
    );
  }
}

class _SwatchWrap extends StatelessWidget {
  const _SwatchWrap({required this.entries});

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppMetrics.space12,
      runSpacing: AppMetrics.space16,
      children: [
        for (final (name, color) in entries) _Swatch(name: name, color: color),
      ],
    );
  }
}

/// 色板：色块 + token 名 + hex 值
class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 96,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppMetrics.br6,
            border: Border.all(color: t.border),
          ),
        ),
        const SizedBox(height: AppMetrics.space4),
        Text(
          name,
          style: AppTextStyles.caption12.copyWith(color: t.textPrimary),
        ),
        Text(
          _hexColor(color),
          style: AppTextStyles.code11.copyWith(color: t.textTertiary),
        ),
      ],
    );
  }
}

// ========== Typography ==========

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  static const _styles = <(String, TextStyle)>[
    ('display20', AppTextStyles.display20),
    ('title16', AppTextStyles.title16),
    ('body13', AppTextStyles.body13),
    ('caption12', AppTextStyles.caption12),
    ('tiny11', AppTextStyles.tiny11),
    ('micro10', AppTextStyles.micro10),
    ('code12', AppTextStyles.code12),
    ('code11', AppTextStyles.code11),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(context.l10n.gallery_typography),
        const SizedBox(height: AppMetrics.space16),
        for (final (name, style) in _styles) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  name,
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.gallery_pangram,
                  style: style.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppMetrics.space8),
        ],
      ],
    );
  }
}

// ========== Metrics ==========

class _MetricsSection extends StatelessWidget {
  const _MetricsSection();

  static const _spacings = <(String, double)>[
    ('space4', AppMetrics.space4),
    ('space8', AppMetrics.space8),
    ('space12', AppMetrics.space12),
    ('space16', AppMetrics.space16),
    ('space20', AppMetrics.space20),
    ('space24', AppMetrics.space24),
    ('space32', AppMetrics.space32),
  ];

  static const _radii = <(String, BorderRadius)>[
    ('br2', AppMetrics.br2),
    ('br4', AppMetrics.br4),
    ('br6', AppMetrics.br6),
    ('br8', AppMetrics.br8),
    ('br10', AppMetrics.br10),
  ];

  static const _heights = <(String, double)>[
    ('height24', AppMetrics.height24),
    ('height28', AppMetrics.height28),
    ('height32', AppMetrics.height32),
    ('height36', AppMetrics.height36),
    ('height38', AppMetrics.height38),
    ('height48', AppMetrics.height48),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(context.l10n.gallery_metrics),
        const SizedBox(height: AppMetrics.space16),
        _GroupLabel(context.l10n.gallery_spacing),
        const SizedBox(height: AppMetrics.space8),
        for (final (name, value) in _spacings) ...[
          _MetricBarRow(
            label: '$name · ${value.toInt()}',
            child: Container(
              width: value,
              height: 12,
              decoration: BoxDecoration(
                color: t.brand,
                borderRadius: AppMetrics.br2,
              ),
            ),
          ),
          const SizedBox(height: AppMetrics.space8),
        ],
        const SizedBox(height: AppMetrics.space8),
        _GroupLabel(context.l10n.gallery_radius),
        const SizedBox(height: AppMetrics.space8),
        Wrap(
          spacing: AppMetrics.space16,
          runSpacing: AppMetrics.space12,
          children: [
            for (final (name, radius) in _radii)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.surfaceVariant,
                      borderRadius: radius,
                      border: Border.all(color: t.borderStrong),
                    ),
                  ),
                  const SizedBox(height: AppMetrics.space4),
                  Text(
                    name,
                    style: AppTextStyles.code11.copyWith(
                      color: t.textTertiary,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppMetrics.space8),
        _GroupLabel(context.l10n.gallery_height),
        const SizedBox(height: AppMetrics.space8),
        for (final (name, value) in _heights) ...[
          _MetricBarRow(
            label: '$name · ${value.toInt()}',
            child: Container(
              width: 120,
              height: value,
              decoration: BoxDecoration(
                color: t.surfaceVariant,
                borderRadius: AppMetrics.br4,
                border: Border.all(color: t.borderStrong),
              ),
            ),
          ),
          const SizedBox(height: AppMetrics.space8),
        ],
      ],
    );
  }
}

/// 左 label（定宽）+ 右可视化内容的度量展示行
class _MetricBarRow extends StatelessWidget {
  const _MetricBarRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.code11.copyWith(
              color: context.appTheme.textSecondary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ========== Shadows ==========

class _ShadowsSection extends StatelessWidget {
  const _ShadowsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(context.l10n.gallery_shadows),
        const SizedBox(height: AppMetrics.space16),
        Wrap(
          spacing: AppMetrics.space24,
          runSpacing: AppMetrics.space16,
          children: [
            _ShadowCard(label: 'shadowSm', shadows: AppShadows.sm(context)),
            _ShadowCard(label: 'shadowMd', shadows: AppShadows.md(context)),
            _ShadowCard(label: context.l10n.gallery_shadowNone, shadows: []),
          ],
        ),
      ],
    );
  }
}

class _ShadowCard extends StatelessWidget {
  const _ShadowCard({required this.label, required this.shadows});

  final String label;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Container(
      width: 180,
      height: 88,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppMetrics.br10,
        border: Border.all(color: t.border),
        boxShadow: shadows,
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.caption12.copyWith(color: t.textSecondary),
        ),
      ),
    );
  }
}

// ========== Components ==========

class _ComponentsSection extends StatelessWidget {
  const _ComponentsSection();

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(context.l10n.gallery_components),
        const SizedBox(height: AppMetrics.space16),

        // AppButton
        const _GroupLabel('AppButton'),
        const SizedBox(height: AppMetrics.space8),
        Wrap(
          spacing: AppMetrics.space8,
          runSpacing: AppMetrics.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton.primary(
                label: context.l10n.gallery_btnPrimary, onPressed: () {}),
            AppButton.secondary(
                label: context.l10n.gallery_btnSecondary, onPressed: () {}),
            AppButton.ghost(
                label: context.l10n.gallery_btnGhost, onPressed: () {}),
            AppButton.danger(
                label: context.l10n.gallery_btnDanger, onPressed: () {}),
            AppButton.primary(
              label: context.l10n.gallery_btnWithIcon,
              icon: Icons.add,
              onPressed: () {},
            ),
            AppButton.primary(
              label: context.l10n.gallery_btnSmall,
              size: AppButtonSize.small,
              onPressed: () {},
            ),
            AppButton.primary(
                label: context.l10n.gallery_btnDisabled, onPressed: null),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppIconButton
        const _GroupLabel('AppIconButton'),
        const SizedBox(height: AppMetrics.space8),
        Wrap(
          spacing: AppMetrics.space8,
          runSpacing: AppMetrics.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppIconButton(
              icon: Icons.refresh,
              tooltip: context.l10n.gallery_tipDefault,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.settings_outlined,
              tooltip: context.l10n.gallery_tipBordered,
              bordered: true,
              onPressed: () {},
            ),
            AppIconButton(
              icon: Icons.delete_outline,
              tooltip: context.l10n.gallery_btnDisabled,
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppTextField
        const _GroupLabel('AppTextField'),
        const SizedBox(height: AppMetrics.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.gallery_textFieldStandard,
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppMetrics.space4),
            const SizedBox(
              width: 280,
              child: AppTextField(hintText: 'https://api.example.com'),
            ),
            const SizedBox(height: AppMetrics.space12),
            Text(
              context.l10n.gallery_textFieldCompact,
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppMetrics.space4),
            SizedBox(
              width: 280,
              child: AppTextField(
                  hintText: context.l10n.gallery_hintSearch, compact: true),
            ),
            const SizedBox(height: AppMetrics.space12),
            Text(
              context.l10n.gallery_textFieldMultiline,
              style: AppTextStyles.caption12.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppMetrics.space4),
            SizedBox(
              width: 280,
              child: AppTextField(
                  hintText: context.l10n.gallery_hintBody, maxLines: 3),
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppSwitch / AppCheckbox
        const _GroupLabel('AppSwitch / AppCheckbox'),
        const SizedBox(height: AppMetrics.space8),
        Wrap(
          spacing: AppMetrics.space24,
          runSpacing: AppMetrics.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Labeled(
              label: context.l10n.gallery_switchOn,
              child: AppSwitch(value: true, onChanged: (_) {}),
            ),
            _Labeled(
              label: context.l10n.gallery_switchOff,
              child: AppSwitch(value: false, onChanged: (_) {}),
            ),
            AppCheckbox(
              value: true,
              label: context.l10n.gallery_checked,
              onChanged: (_) {},
            ),
            AppCheckbox(
              value: false,
              label: context.l10n.gallery_unchecked,
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppTabs
        const _GroupLabel('AppTabs'),
        const SizedBox(height: AppMetrics.space8),
        AppTabs(
          tabs: [
            AppTabItem(label: context.l10n.request_params, count: 3),
            AppTabItem(label: context.l10n.request_headers, count: 2),
            AppTabItem(label: context.l10n.request_body, dot: true),
          ],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppCard
        const _GroupLabel('AppCard'),
        const SizedBox(height: AppMetrics.space8),
        Wrap(
          spacing: AppMetrics.space16,
          runSpacing: AppMetrics.space16,
          children: [
            SizedBox(
              width: 240,
              child: AppCard(
                child: Text(
                  context.l10n.gallery_cardStandard,
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: AppCard.elevated(
                child: Text(
                  context.l10n.gallery_cardElevated,
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // MethodBadge
        const _GroupLabel('MethodBadge'),
        const SizedBox(height: AppMetrics.space8),
        const Wrap(
          spacing: AppMetrics.space8,
          runSpacing: AppMetrics.space8,
          children: [
            MethodBadge('GET'),
            MethodBadge('POST'),
            MethodBadge('PUT'),
            MethodBadge('DELETE'),
            MethodBadge('PATCH'),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // StatusChip
        const _GroupLabel('StatusChip'),
        const SizedBox(height: AppMetrics.space8),
        const Wrap(
          spacing: AppMetrics.space8,
          runSpacing: AppMetrics.space8,
          children: [
            StatusChip(200),
            StatusChip(301),
            StatusChip(404),
            StatusChip(500),
          ],
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppPopupSelect
        const _GroupLabel('AppPopupSelect'),
        const SizedBox(height: AppMetrics.space8),
        SizedBox(
          width: 200,
          child: AppPopupSelect<String>(
            value: 'dev',
            hint: context.l10n.gallery_selectEnvHint,
            boxed: true,
            items: const [
              AppPopupSelectEntry(value: 'dev', label: 'Development'),
              AppPopupSelectEntry(value: 'staging', label: 'Staging'),
              AppPopupSelectEntry(value: 'prod', label: 'Production'),
            ],
            onSelected: (_) {},
          ),
        ),
        const SizedBox(height: AppMetrics.space16),

        // AppDivider
        const _GroupLabel('AppDivider'),
        const SizedBox(height: AppMetrics.space8),
        const SizedBox(width: 280, child: AppDivider()),
        const SizedBox(height: AppMetrics.space8),
        const SizedBox(width: 280, child: AppDivider(subtle: true)),
        const SizedBox(height: AppMetrics.space16),

        // AppEmptyState
        const _GroupLabel('AppEmptyState'),
        const SizedBox(height: AppMetrics.space8),
        Container(
          width: 320,
          height: 220,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppMetrics.br10,
            border: Border.all(color: t.border),
          ),
          child: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: context.l10n.main_emptyTitle,
            subtitle: context.l10n.gallery_emptyDemoSubtitle,
            action: AppButton.primary(
                label: context.l10n.sidebar_newRequest, onPressed: () {}),
          ),
        ),
      ],
    );
  }
}
