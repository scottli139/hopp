import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/auth_config.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../services/auth_resolver.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_dialog.dart';
import '../common/app_divider.dart';
import '../common/app_text_field.dart';
import '../request/auth_config_editor.dart';
import '../request/pre_request_chain_editor.dart';

/// 集合设置对话框（F8.1 引入）
///
/// 左侧分区导航 + 右侧内容：
/// - General：名称 / 描述
/// - Auth：集合级默认认证（被集合下请求继承；F8.2 将在此追加
///   Pre-request chain 分区）
///
/// 与请求编辑不同，集合改动即时持久化（无 dirty 概念），
/// 与「管理环境」对话框的交互一致。
class CollectionSettingsDialog extends ConsumerStatefulWidget {
  const CollectionSettingsDialog({super.key, required this.collection});

  final Collection collection;

  static Future<void> show(BuildContext context, Collection collection) {
    // 直接用 showDialog：showAppDialog 未暴露 showDividers/contentPadding
    return showDialog<void>(
      context: context,
      builder: (_) => CollectionSettingsDialog(collection: collection),
    );
  }

  @override
  ConsumerState<CollectionSettingsDialog> createState() =>
      _CollectionSettingsDialogState();
}

class _CollectionSettingsDialogState
    extends ConsumerState<CollectionSettingsDialog> {
  int _sectionIndex = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descController =
        TextEditingController(text: widget.collection.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _update(Collection Function(Collection) transform) {
    final latest = ref
            .read(collectionProvider)
            .valueOrNull
            ?.where((c) => c.id == widget.collection.id)
            .firstOrNull ??
        widget.collection;
    ref.read(collectionProvider.notifier).updateCollection(transform(latest));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    // 订阅集合变化，Auth 编辑器的展示值始终取最新持久化状态
    final collection = ref
            .watch(collectionProvider)
            .valueOrNull
            ?.where((c) => c.id == widget.collection.id)
            .firstOrNull ??
        widget.collection;

    return AppDialog(
      title: context.l10n.collectionSettings_title(collection.name),
      width: 680,
      height: 480,
      contentPadding: EdgeInsets.zero,
      showDividers: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧分区导航
          Container(
            width: 168,
            color: t.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppMetrics.space8,
              vertical: AppMetrics.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppMetrics.space8,
                    bottom: AppMetrics.space8,
                  ),
                  child: Text(
                    context.l10n.collectionSettings_sectionHeader,
                    style: AppTextStyles.micro10.copyWith(
                      color: t.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.info_outline,
                  label: context.l10n.collectionSettings_navGeneral,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.lock_outline,
                  label: context.l10n.request_auth,
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.account_tree_outlined,
                  label: context.l10n.collectionSettings_navPreRequest,
                ),
              ],
            ),
          ),
          const AppDivider.vertical(),
          // 右侧内容
          Expanded(
            child: switch (_sectionIndex) {
              0 => _buildGeneralSection(context, collection),
              1 => _buildAuthSection(context, collection),
              _ => _buildPreRequestSection(context, collection),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final t = context.appTheme;
    final selected = _sectionIndex == index;

    return _HoverableNavItem(
      selected: selected,
      onTap: () => setState(() => _sectionIndex = index),
      child: Row(
        children: [
          Icon(icon, size: 15, color: selected ? t.brand : t.textTertiary),
          const SizedBox(width: AppMetrics.space8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body13.copyWith(
                color: selected ? t.brand : t.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context, Collection collection) {
    final t = context.appTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppMetrics.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.collectionSettings_navGeneral,
            style: AppTextStyles.title16.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppMetrics.space16),
          _buildLabeledField(
            context,
            label: context.l10n.collectionSettings_nameLabel,
            child: AppTextField(
              controller: _nameController,
              onChanged: (v) => _update((c) => c.copyWith(name: v)),
            ),
          ),
          _buildLabeledField(
            context,
            label: context.l10n.collectionSettings_descLabel,
            child: AppTextField(
              controller: _descController,
              hintText: context.l10n.collectionSettings_descHint,
              // 注意：freezed copyWith 无法把可空字段改回 null，空描述存空串
              onChanged: (v) => _update((c) => c.copyWith(description: v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection(BuildContext context, Collection collection) {
    String? inheritedSummary;
    if (collection.auth.type == AuthType.inherit) {
      final collectionsById = ref.watch(collectionsByIdProvider);
      final source =
          AuthResolver.inheritedFromCollection(collection, collectionsById);
      if (source != null && source.auth.type != AuthType.none) {
        inheritedSummary =
            context.l10n.collectionSettings_inheritFrom(source.name);
      } else if (source != null) {
        inheritedSummary =
            context.l10n.collectionSettings_inheritNoAuth(source.name);
      } else if (collection.parentId == null) {
        inheritedSummary = context.l10n.collectionSettings_rootInherit;
      }
    }

    return AuthConfigEditor(
      auth: collection.auth,
      allowInherit: true,
      inheritedSummary: inheritedSummary,
      onChanged: (auth) => _update((c) => c.copyWith(auth: auth)),
    );
  }

  /// Pre-request 分区（F8.2）：集合级默认前置链，被集合下请求继承
  Widget _buildPreRequestSection(BuildContext context, Collection collection) {
    return PreRequestChainEditor(
      chain: collection.preRequestChain,
      retryOn401: collection.preRequestRetryOn401,
      ownerId: collection.id,
      onChainChanged: (chain) =>
          _update((c) => c.copyWith(preRequestChain: chain)),
      onRetryChanged: (v) =>
          _update((c) => c.copyWith(preRequestRetryOn401: v)),
      onTestRun: () {
        ref
            .read(requestResponseProvider.notifier)
            .testRunPreRequestChain(collection.id, collection.preRequestChain);
      },
    );
  }

  Widget _buildLabeledField(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppMetrics.space12),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTextStyles.caption12.copyWith(
                color: context.appTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppMetrics.space12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 分区导航项（hover / selected 态）
class _HoverableNavItem extends StatefulWidget {
  const _HoverableNavItem({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HoverableNavItem> createState() => _HoverableNavItemState();
}

class _HoverableNavItemState extends State<_HoverableNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppMetrics.space8),
          decoration: BoxDecoration(
            color: widget.selected
                ? t.brandSoft
                : (_hovering ? t.surfaceVariant : null),
            borderRadius: AppMetrics.br6,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
