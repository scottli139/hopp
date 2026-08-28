/// OpenAPI/Swagger 导入 Provider
///
/// 驱动导入对话框 OpenAPI 页签的四态流程：
/// 输入（idle）→ 解析预览（preview，勾选/搜索）→ 导入（importing）→
/// 冲突解决（conflict）→ 结果报告（success）。错误统一落 error 态。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/http_request.dart';
import '../../services/import_export/import_export_exception.dart';
import '../../services/import_export/openapi/openapi_import_service.dart';
import '../../services/import_export/openapi/openapi_mapper.dart';
import '../../services/import_export/openapi/openapi_parser.dart';
import '../../services/import_export/openapi/openapi_spec.dart';
import '../../utils/app_logger.dart';
import '../collection/collection_provider.dart';
import '../core/providers.dart';
import '../environment/environment_provider.dart';

/// 导入阶段
enum OpenApiImportStage {
  /// 输入（文件 / URL）
  idle,

  /// 解析中
  parsing,

  /// 解析预览（勾选）
  preview,

  /// 导入中
  importing,

  /// 同名集合冲突，等待用户决策
  conflict,

  /// 导入完成（结果报告）
  success,

  /// 失败
  error,
}

/// OpenAPI 导入状态
class OpenApiImportState {
  const OpenApiImportState({
    required this.stage,
    this.rawContent,
    this.sourceLabel = '',
    this.sourceUrl,
    this.sourceHeaderName,
    this.sourceHeaderValue,
    this.spec,
    this.selectedIds = const {},
    this.searchQuery = '',
    this.error,
    this.conflictCollection,
    this.existingId,
    this.childCollections,
    this.allRequests,
    this.baseUrl,
    this.placeholders = const [],
    this.oauthNotices = const [],
    this.authDescription,
    this.report,
  });

  /// 当前阶段
  final OpenApiImportStage stage;

  /// 文档原文（文件 / 内联来源；URL 来源为 null，导入时重新拉取）
  final String? rawContent;

  /// 来源标签（文件名或 URL）
  final String sourceLabel;

  /// URL 来源（parseUrl 时记录，importSpec 直传 url）
  final String? sourceUrl;

  /// URL 自定义请求头名
  final String? sourceHeaderName;

  /// URL 自定义请求头值
  final String? sourceHeaderValue;

  /// 解析结果（preview 起可用）
  final OpenApiSpec? spec;

  /// 勾选的 operation id 集合（默认全选）
  final Set<String> selectedIds;

  /// 预览搜索词（path / name 包含，大小写不敏感）
  final String searchQuery;

  /// 错误信息（error 态）
  final String? error;

  // ========== 冲突暂存（供 resolveConflict 回传） ==========

  /// 冲突的新集合（未保存）
  final Collection? conflictCollection;

  /// 已存在的同名集合 ID
  final String? existingId;

  /// 冲突时的子集合列表（扁平化存储）
  final List<Collection>? childCollections;

  /// 冲突时的所有请求列表
  final List<HttpRequest>? allRequests;

  /// 待 upsert 的全局变量 baseUrl
  final String? baseUrl;

  /// 需用户补全的占位说明
  final List<ImportPlaceholder> placeholders;

  /// 未自动配置的 OAuth2 / OpenID Connect scheme 名
  final List<String> oauthNotices;

  /// 认证配置描述
  final String? authDescription;

  /// 导入报告（success 态）
  final OpenApiReport? report;

  factory OpenApiImportState.idle() =>
      const OpenApiImportState(stage: OpenApiImportStage.idle);

  OpenApiImportState copyWith({
    OpenApiImportStage? stage,
    String? rawContent,
    String? sourceLabel,
    String? sourceUrl,
    String? sourceHeaderName,
    String? sourceHeaderValue,
    OpenApiSpec? spec,
    Set<String>? selectedIds,
    String? searchQuery,
    String? error,
    Collection? conflictCollection,
    String? existingId,
    List<Collection>? childCollections,
    List<HttpRequest>? allRequests,
    String? baseUrl,
    List<ImportPlaceholder>? placeholders,
    List<String>? oauthNotices,
    String? authDescription,
    OpenApiReport? report,
  }) {
    return OpenApiImportState(
      stage: stage ?? this.stage,
      rawContent: rawContent ?? this.rawContent,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceHeaderName: sourceHeaderName ?? this.sourceHeaderName,
      sourceHeaderValue: sourceHeaderValue ?? this.sourceHeaderValue,
      spec: spec ?? this.spec,
      selectedIds: selectedIds ?? this.selectedIds,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
      conflictCollection: conflictCollection ?? this.conflictCollection,
      existingId: existingId ?? this.existingId,
      childCollections: childCollections ?? this.childCollections,
      allRequests: allRequests ?? this.allRequests,
      baseUrl: baseUrl ?? this.baseUrl,
      placeholders: placeholders ?? this.placeholders,
      oauthNotices: oauthNotices ?? this.oauthNotices,
      authDescription: authDescription ?? this.authDescription,
      report: report ?? this.report,
    );
  }
}

/// OpenAPI 导入 Notifier
class OpenApiImportNotifier extends StateNotifier<OpenApiImportState>
    with LogMixin {
  final Ref _ref;

  OpenApiImportNotifier(this._ref) : super(OpenApiImportState.idle());

  OpenApiImportService get _service => _ref.read(openApiImportServiceProvider);

  /// 解析本地文件
  Future<void> parseFile(String path) async {
    logInfo('Parsing OpenAPI file: $path');
    state = OpenApiImportState(
      stage: OpenApiImportStage.parsing,
      sourceLabel: path.split('/').last,
    );

    try {
      final content = await _service.readFile(path);
      final spec = OpenApiParser().parse(content);
      _toPreview(spec, rawContent: content);
    } on ImportException catch (e) {
      logError('OpenAPI parse exception', e);
      state = _errorState(e.message);
    } catch (e, stack) {
      logError('OpenAPI parse failed', e, stack);
      state = _errorState('Parse failed: $e');
    }
  }

  /// 拉取并解析 URL 文档
  ///
  /// 注意：[OpenApiImportService.fetchFromUrl] 返回的是解析后的
  /// [OpenApiSpec]（非原文），因此 URL 来源不持有 rawContent，
  /// 导入时把 url/header 直传 importSpec 重新拉取。
  Future<void> parseUrl(
    String url, {
    String? headerName,
    String? headerValue,
  }) async {
    logInfo('Parsing OpenAPI URL: $url');
    state = OpenApiImportState(
      stage: OpenApiImportStage.parsing,
      sourceLabel: url,
      sourceUrl: url,
      sourceHeaderName: headerName,
      sourceHeaderValue: headerValue,
    );

    try {
      final spec = await _service.fetchFromUrl(
        url,
        headerName: headerName,
        headerValue: headerValue,
      );
      _toPreview(spec);
    } on ImportException catch (e) {
      logError('OpenAPI fetch exception', e);
      state = _errorState(e.message);
    } catch (e, stack) {
      logError('OpenAPI fetch failed', e, stack);
      state = _errorState('Fetch failed: $e');
    }
  }

  /// 解析内联内容（test-mode / 测试用）
  Future<void> parseContent(
    String content, {
    String sourceLabel = 'inline',
  }) async {
    logInfo('Parsing inline OpenAPI content ($sourceLabel)');
    state = OpenApiImportState(
      stage: OpenApiImportStage.parsing,
      sourceLabel: sourceLabel,
    );

    try {
      final spec = OpenApiParser().parse(content);
      _toPreview(spec, rawContent: content);
    } on ImportException catch (e) {
      logError('OpenAPI parse exception', e);
      state = _errorState(e.message);
    } catch (e, stack) {
      logError('OpenAPI parse failed', e, stack);
      state = _errorState('Parse failed: $e');
    }
  }

  /// 解析成功 → preview（默认全选、清空搜索）
  void _toPreview(OpenApiSpec spec, {String? rawContent}) {
    state = state.copyWith(
      stage: OpenApiImportStage.preview,
      rawContent: rawContent,
      spec: spec,
      selectedIds: {for (final op in spec.operations) op.id},
      searchQuery: '',
    );
  }

  OpenApiImportState _errorState(String message) => state.copyWith(
        stage: OpenApiImportStage.error,
        error: message,
      );

  /// 切换单个 operation 勾选
  void toggleOp(String id) {
    final selected = Set<String>.of(state.selectedIds);
    if (!selected.remove(id)) {
      selected.add(id);
    }
    state = state.copyWith(selectedIds: selected);
  }

  /// 按 tag 整组勾选/取消（tag 为 '' 表示无 tag 组；只作用于当前
  /// 搜索过滤后可见的 operation）
  void toggleTag(String tag, bool select) {
    final spec = state.spec;
    if (spec == null) {
      return;
    }
    final selected = Set<String>.of(state.selectedIds);
    for (final op in spec.operations) {
      if ((op.tag ?? '') != tag || !_matchesSearch(op)) {
        continue;
      }
      if (select) {
        selected.add(op.id);
      } else {
        selected.remove(op.id);
      }
    }
    state = state.copyWith(selectedIds: selected);
  }

  /// 全选 / 全不选（作用于全部 operation，与搜索无关）
  void selectAll(bool select) {
    final spec = state.spec;
    if (spec == null) {
      return;
    }
    state = state.copyWith(
      selectedIds:
          select ? {for (final op in spec.operations) op.id} : const {},
    );
  }

  /// 更新预览搜索词
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// operation 是否命中当前搜索词
  bool _matchesSearch(OpenApiOperation op) {
    final query = state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return op.path.toLowerCase().contains(query) ||
        op.name.toLowerCase().contains(query);
  }

  /// 当前搜索过滤后的 operation 列表（供 UI 分组渲染）
  List<OpenApiOperation> get filteredOperations {
    final spec = state.spec;
    if (spec == null) {
      return const [];
    }
    return spec.operations.where(_matchesSearch).toList();
  }

  /// 导入勾选的 operation
  Future<void> importSelected() async {
    if (state.selectedIds.isEmpty) {
      logWarning('No operations selected, skip import');
      return;
    }

    logInfo('Importing ${state.selectedIds.length} selected operations...');
    state = state.copyWith(stage: OpenApiImportStage.importing);

    try {
      final outcome = await _service.importSpec(
        content: state.rawContent,
        url: state.rawContent == null ? state.sourceUrl : null,
        headerName: state.sourceHeaderName,
        headerValue: state.sourceHeaderValue,
        selectedOpIds: state.selectedIds,
      );
      await _handleOutcome(outcome);
    } on ImportException catch (e) {
      logError('OpenAPI import exception', e);
      state = _errorState(e.message);
    } catch (e, stack) {
      logError('OpenAPI import failed', e, stack);
      state = _errorState('Import failed: $e');
    }
  }

  /// 解决同名集合冲突
  Future<void> resolveConflict(ConflictResolution resolution) async {
    final collection = state.conflictCollection;
    if (collection == null) {
      logWarning('No conflict to resolve');
      return;
    }

    logInfo('Resolving OpenAPI import conflict: ${resolution.name}');
    state = state.copyWith(stage: OpenApiImportStage.importing);

    try {
      final outcome = await _service.resolveConflict(
        resolution: resolution,
        collection: collection,
        existingId: state.existingId,
        childCollections: state.childCollections,
        allRequests: state.allRequests,
        baseUrl: state.baseUrl,
        placeholders: state.placeholders,
        oauthNotices: state.oauthNotices,
        authDescription: state.authDescription,
      );
      await _handleOutcome(outcome);
    } on ImportException catch (e) {
      logError('Resolve conflict exception', e);
      state = _errorState(e.message);
    } catch (e, stack) {
      logError('Resolve conflict failed', e, stack);
      state = _errorState('Resolve conflict failed: $e');
    }
  }

  /// 统一处理导入结果：success → 刷新集合与全局变量；conflict →
  /// 暂存冲突数据；skipped → 回到 idle
  Future<void> _handleOutcome(OpenApiImportOutcome outcome) async {
    switch (outcome.status) {
      case OpenApiImportStatus.success:
        final report = outcome.report!;
        logInfo(
          'OpenAPI import success: ${report.collectionId} '
          '(${report.requestCount} requests)',
        );
        await _ref.read(collectionProvider.notifier).loadCollections();
        await _ref.read(globalVariablesProvider.notifier).reload();
        state = state.copyWith(
          stage: OpenApiImportStage.success,
          report: report,
        );
      case OpenApiImportStatus.conflict:
        logInfo('OpenAPI import conflict: ${outcome.conflictCollection?.name}');
        final report = outcome.report;
        state = state.copyWith(
          stage: OpenApiImportStage.conflict,
          conflictCollection: outcome.conflictCollection,
          existingId: outcome.existingId,
          childCollections: outcome.childCollections,
          allRequests: outcome.allRequests,
          baseUrl: report?.baseUrl,
          placeholders: report?.placeholders ?? const [],
          oauthNotices: report?.oauthNotices ?? const [],
          authDescription: report?.authDescription,
        );
      case OpenApiImportStatus.skipped:
        logInfo('OpenAPI import skipped');
        state = OpenApiImportState.idle();
    }
  }

  /// 重置回输入态
  void reset() {
    logDebug('Resetting OpenAPI import state');
    state = OpenApiImportState.idle();
  }
}

/// OpenAPI 导入服务 Provider（单例）
final openApiImportServiceProvider = Provider<OpenApiImportService>((ref) {
  return OpenApiImportService(ref.read(storageServiceProvider));
});

/// OpenAPI 导入 Provider
final openApiImportProvider =
    StateNotifierProvider<OpenApiImportNotifier, OpenApiImportState>((ref) {
  return OpenApiImportNotifier(ref);
});
