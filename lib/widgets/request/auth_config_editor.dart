import 'package:flutter/material.dart';
import 'package:hopp/l10n/l10n.dart';

import '../../models/auth_config.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_data.dart';
import '../common/app_button.dart';
import '../common/app_popup_menu.dart';
import '../common/app_text_field.dart';

/// 认证配置编辑器（F8.1）
///
/// 左侧类型列表 + 右侧表单的固定布局，按 UI 原型
/// `docs/design/f8_prerequest_chain_preview.html` 实现。
/// 请求 Auth tab 与集合设置对话框复用本组件：
/// - [allowInherit] 控制类型列表是否包含 Inherit 项
/// - [inheritedSummary] 在选中 Inherit 时展示来源说明（如「继承自集合 X」）
///
/// 所有编辑通过 [onChanged] 即时回写完整 [AuthConfig]（含未激活类型
/// 的字段，切换类型不丢已填内容）。secret 字段（token/password/
/// apiKeyValue）默认脱敏，显隐状态为会话态、不持久化。
class AuthConfigEditor extends StatefulWidget {
  const AuthConfigEditor({
    super.key,
    required this.auth,
    required this.onChanged,
    this.allowInherit = true,
    this.inheritedSummary,
  });

  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;
  final bool allowInherit;

  /// Inherit 态的来源说明文案；为 null 时使用通用兜底文案
  final String? inheritedSummary;

  @override
  State<AuthConfigEditor> createState() => _AuthConfigEditorState();
}

class _AuthConfigEditorState extends State<AuthConfigEditor> {
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiKeyNameController = TextEditingController();
  final _apiKeyValueController = TextEditingController();

  bool _tokenRevealed = false;
  bool _passwordRevealed = false;
  bool _apiKeyValueRevealed = false;

  @override
  void initState() {
    super.initState();
    _syncControllers(widget.auth);
  }

  @override
  void didUpdateWidget(AuthConfigEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers(widget.auth);
  }

  /// 外部值与输入框不一致时才回写，避免打字过程中被 provider 回读覆盖
  void _syncControllers(AuthConfig auth) {
    void sync(TextEditingController c, String value) {
      if (c.text != value) c.text = value;
    }

    sync(_tokenController, auth.token);
    sync(_usernameController, auth.username);
    sync(_passwordController, auth.password);
    sync(_apiKeyNameController, auth.apiKeyName);
    sync(_apiKeyValueController, auth.apiKeyValue);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _apiKeyNameController.dispose();
    _apiKeyValueController.dispose();
    super.dispose();
  }

  void _emit(AuthConfig auth) => widget.onChanged(auth);

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧类型列表
        Container(
          width: 200,
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
                  context.l10n.auth_typeSectionTitle,
                  style: AppTextStyles.micro10.copyWith(
                    color: t.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (widget.allowInherit)
                _buildTypeItem(
                  context,
                  type: AuthType.inherit,
                  icon: Icons.move_up,
                  label: context.l10n.auth_typeInherit,
                ),
              _buildTypeItem(
                context,
                type: AuthType.none,
                icon: Icons.block,
                label: context.l10n.auth_typeNone,
              ),
              _buildTypeItem(
                context,
                type: AuthType.bearer,
                icon: Icons.confirmation_number_outlined,
                label: context.l10n.auth_typeBearer,
              ),
              _buildTypeItem(
                context,
                type: AuthType.basic,
                icon: Icons.lock_outline,
                label: context.l10n.auth_typeBasic,
              ),
              _buildTypeItem(
                context,
                type: AuthType.apiKey,
                icon: Icons.vpn_key_outlined,
                label: context.l10n.auth_typeApiKey,
              ),
            ],
          ),
        ),
        // 右侧表单
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppMetrics.space20),
            child: _buildForm(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeItem(
    BuildContext context, {
    required AuthType type,
    required IconData icon,
    required String label,
  }) {
    final t = context.appTheme;
    final selected = widget.auth.type == type;

    return _HoverableItem(
      selected: selected,
      onTap: () => _emit(widget.auth.copyWith(type: type)),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: selected ? t.brand : t.textTertiary,
          ),
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

  Widget _buildForm(BuildContext context) {
    switch (widget.auth.type) {
      case AuthType.inherit:
        return _buildInheritForm(context);
      case AuthType.none:
        return _buildNoneForm(context);
      case AuthType.bearer:
        return _buildBearerForm(context);
      case AuthType.basic:
        return _buildBasicForm(context);
      case AuthType.apiKey:
        return _buildApiKeyForm(context);
    }
  }

  Widget _buildInheritForm(BuildContext context) {
    final t = context.appTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormTitle(context, context.l10n.auth_typeInherit),
        _buildFormDesc(context, context.l10n.auth_inheritDesc),
        const SizedBox(height: AppMetrics.space16),
        Container(
          padding: const EdgeInsets.all(AppMetrics.space12),
          decoration: BoxDecoration(
            color: t.infoSoft,
            borderRadius: AppMetrics.br6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: t.info),
              const SizedBox(width: AppMetrics.space8),
              Expanded(
                child: Text(
                  widget.inheritedSummary ?? context.l10n.auth_inheritNotFound,
                  style: AppTextStyles.caption12.copyWith(
                    color: t.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoneForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormTitle(context, context.l10n.auth_typeNone),
        _buildFormDesc(context, context.l10n.auth_noneDesc),
      ],
    );
  }

  Widget _buildBearerForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormTitle(context, context.l10n.auth_typeBearer),
        _buildFormDesc(
          context,
          context.l10n.auth_bearerDesc,
        ),
        const SizedBox(height: AppMetrics.space16),
        _buildFieldRow(
          context,
          label: context.l10n.auth_tokenLabel,
          controller: _tokenController,
          hintText: '{{token}}',
          secret: true,
          revealed: _tokenRevealed,
          onToggleReveal: () =>
              setState(() => _tokenRevealed = !_tokenRevealed),
          onChanged: (v) => _emit(widget.auth.copyWith(token: v)),
        ),
        _buildVariableHint(context),
      ],
    );
  }

  Widget _buildBasicForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormTitle(context, context.l10n.auth_typeBasic),
        _buildFormDesc(
          context,
          context.l10n.auth_basicDesc,
        ),
        const SizedBox(height: AppMetrics.space16),
        _buildFieldRow(
          context,
          label: context.l10n.auth_username,
          controller: _usernameController,
          hintText: '{{username}}',
          onChanged: (v) => _emit(widget.auth.copyWith(username: v)),
        ),
        _buildFieldRow(
          context,
          label: context.l10n.auth_password,
          controller: _passwordController,
          hintText: '{{password}}',
          secret: true,
          revealed: _passwordRevealed,
          onToggleReveal: () =>
              setState(() => _passwordRevealed = !_passwordRevealed),
          onChanged: (v) => _emit(widget.auth.copyWith(password: v)),
        ),
        _buildVariableHint(context),
      ],
    );
  }

  Widget _buildApiKeyForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormTitle(context, context.l10n.auth_typeApiKey),
        _buildFormDesc(context, context.l10n.auth_apiKeyDesc),
        const SizedBox(height: AppMetrics.space16),
        _buildFieldRow(
          context,
          label: context.l10n.auth_keyLabel,
          controller: _apiKeyNameController,
          hintText: 'X-API-Key',
          onChanged: (v) => _emit(widget.auth.copyWith(apiKeyName: v)),
        ),
        _buildFieldRow(
          context,
          label: context.l10n.request_valueColumn,
          controller: _apiKeyValueController,
          hintText: '{{api_key}}',
          secret: true,
          revealed: _apiKeyValueRevealed,
          onToggleReveal: () =>
              setState(() => _apiKeyValueRevealed = !_apiKeyValueRevealed),
          onChanged: (v) => _emit(widget.auth.copyWith(apiKeyValue: v)),
        ),
        _buildFieldLabelRow(
          context,
          label: context.l10n.auth_addTo,
          child: AppPopupSelect<String>(
            value: widget.auth.apiKeyAddTo,
            boxed: true,
            items: [
              AppPopupSelectEntry(
                value: AuthConfig.apiKeyAddToHeader,
                label: context.l10n.auth_addToHeader,
              ),
              AppPopupSelectEntry(
                value: AuthConfig.apiKeyAddToQuery,
                label: context.l10n.auth_addToQuery,
              ),
            ],
            onSelected: (v) => _emit(widget.auth.copyWith(apiKeyAddTo: v)),
          ),
        ),
        _buildVariableHint(context),
      ],
    );
  }

  Widget _buildFormTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.title16.copyWith(
        color: context.appTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFormDesc(BuildContext context, String desc) {
    return Padding(
      padding: const EdgeInsets.only(top: AppMetrics.space4),
      child: Text(
        desc,
        style: AppTextStyles.caption12.copyWith(
          color: context.appTheme.textTertiary,
          height: 1.5,
        ),
      ),
    );
  }

  /// 表单行：label + 输入框（secret 时带显隐切换）
  Widget _buildFieldRow(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? hintText,
    bool secret = false,
    bool revealed = false,
    VoidCallback? onToggleReveal,
  }) {
    return _buildFieldLabelRow(
      context,
      label: label,
      child: AppTextField(
        controller: controller,
        hintText: hintText,
        obscureText: secret && !revealed,
        onChanged: onChanged,
        suffix: secret
            ? AppIconButton(
                icon: revealed ? Icons.visibility_off : Icons.visibility,
                size: 24,
                iconSize: 14,
                tooltip: revealed
                    ? context.l10n.common_hide
                    : context.l10n.common_show,
                onPressed: onToggleReveal,
              )
            : null,
      ),
    );
  }

  Widget _buildFieldLabelRow(
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

  Widget _buildVariableHint(BuildContext context) {
    return Text(
      context.l10n.auth_variableHint('{{password | sha1}}', '{{variable}}'),
      style: AppTextStyles.tiny11.copyWith(
        color: context.appTheme.textTertiary,
        height: 1.5,
      ),
    );
  }
}

/// 类型列表项（hover / selected 态）
class _HoverableItem extends StatefulWidget {
  const _HoverableItem({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Widget child;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HoverableItem> createState() => _HoverableItemState();
}

class _HoverableItemState extends State<_HoverableItem> {
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
