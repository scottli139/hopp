/// Import/Export Provider
///
/// 管理导入/导出的状态和业务逻辑。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../providers/collection/collection_provider.dart';
import '../../services/import_export/import_export_exception.dart';
import '../../services/import_export/postman_export_service.dart';
import '../../services/import_export/postman_import_service.dart';
import '../../utils/app_logger.dart';
import '../core/providers.dart';

/// 导入/导出状态
class ImportExportState {
  /// 是否正在处理
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 导入结果
  final ImportResult? importResult;

  /// 导出路径
  final String? exportPath;

  /// 冲突信息
  final ImportConflict? conflict;

  const ImportExportState({
    this.isLoading = false,
    this.error,
    this.importResult,
    this.exportPath,
    this.conflict,
  });

  factory ImportExportState.idle() => const ImportExportState();

  factory ImportExportState.loading() =>
      const ImportExportState(isLoading: true);

  factory ImportExportState.success(ImportResult result) =>
      ImportExportState(importResult: result);

  factory ImportExportState.error(String message) =>
      ImportExportState(error: message);

  factory ImportExportState.conflict(ImportConflict conflict) =>
      ImportExportState(conflict: conflict);

  ImportExportState copyWith({
    bool? isLoading,
    String? error,
    ImportResult? importResult,
    String? exportPath,
    ImportConflict? conflict,
  }) {
    return ImportExportState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      importResult: importResult ?? this.importResult,
      exportPath: exportPath ?? this.exportPath,
      conflict: conflict ?? this.conflict,
    );
  }
}

/// 导入冲突信息
class ImportConflict {
  final Collection collection;
  final String existingId;

  const ImportConflict({
    required this.collection,
    required this.existingId,
  });
}

/// 导入/导出 Notifier
class ImportExportNotifier extends StateNotifier<ImportExportState>
    with LogMixin {
  final Ref _ref;
  PostmanImportService? _importService;
  PostmanExportService? _exportService;

  ImportExportNotifier(this._ref) : super(ImportExportState.idle());

  /// 获取导入服务
  PostmanImportService get _import {
    _importService ??= PostmanImportService(_ref.read(storageServiceProvider));
    return _importService!;
  }

  /// 获取导出服务
  PostmanExportService get _export {
    _exportService ??= PostmanExportService(_ref.read(storageServiceProvider));
    return _exportService!;
  }

  /// 导入文件
  Future<void> importFile(String filePath) async {
    logInfo('Starting import: $filePath');
    state = ImportExportState.loading();

    try {
      final result = await _import.importFile(filePath);

      if (result.success) {
        logInfo('Import successful: ${result.collectionId}');
        // 刷新集合列表
        await _ref.read(collectionProvider.notifier).loadCollections();
        state = ImportExportState.success(result);
      } else if (result.conflictCollection != null &&
          result.existingId != null) {
        logInfo('Import conflict detected: ${result.conflictCollection!.name}');
        state = ImportExportState.conflict(
          ImportConflict(
            collection: result.conflictCollection!,
            existingId: result.existingId!,
          ),
        );
      } else {
        state = ImportExportState.error(
          result.errorMessage ?? '导入失败',
        );
      }
    } on ImportException catch (e) {
      logError('Import exception', e);
      state = ImportExportState.error(e.message);
    } catch (e, stack) {
      logError('Import failed', e, stack);
      state = ImportExportState.error('导入失败: $e');
    }
  }

  /// 解决冲突
  Future<void> resolveConflict(ConflictResolution resolution) async {
    if (state.conflict == null) {
      logWarning('No conflict to resolve');
      return;
    }

    logInfo('Resolving conflict with: ${resolution.name}');
    state = ImportExportState.loading();

    try {
      final result = await _import.resolveConflict(
        collection: state.conflict!.collection,
        resolution: resolution,
        existingId: state.conflict!.existingId,
      );

      if (result.success) {
        logInfo('Conflict resolved: ${result.collectionId}');
        // 刷新集合列表
        await _ref.read(collectionProvider.notifier).loadCollections();
        state = ImportExportState.success(result);
      } else if (result.skipped) {
        logInfo('Import skipped');
        state = ImportExportState.idle();
      } else {
        state = ImportExportState.error(
          result.errorMessage ?? '解决冲突失败',
        );
      }
    } on ImportException catch (e) {
      logError('Resolve conflict exception', e);
      state = ImportExportState.error(e.message);
    } catch (e, stack) {
      logError('Resolve conflict failed', e, stack);
      state = ImportExportState.error('解决冲突失败: $e');
    }
  }

  /// 导出集合
  Future<void> exportCollection({
    required String collectionId,
    required String savePath,
    bool prettyPrint = true,
  }) async {
    logInfo('Starting export: $collectionId to $savePath');
    state = ImportExportState.loading();

    try {
      await _export.exportCollection(
        collectionId: collectionId,
        savePath: savePath,
        options: ExportOptions(
          prettyPrint: prettyPrint,
        ),
      );

      logInfo('Export successful: $savePath');
      state = ImportExportState(exportPath: savePath);
    } on ExportException catch (e) {
      logError('Export exception', e);
      state = ImportExportState.error(e.message);
    } catch (e, stack) {
      logError('Export failed', e, stack);
      state = ImportExportState.error('导出失败: $e');
    }
  }

  /// 重置状态
  void reset() {
    logDebug('Resetting import/export state');
    state = ImportExportState.idle();
  }

  /// 清除错误
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// 导入/导出 Provider
final importExportProvider =
    StateNotifierProvider<ImportExportNotifier, ImportExportState>((ref) {
  return ImportExportNotifier(ref);
});

/// 导入服务 Provider（单例）
final postmanImportServiceProvider = Provider<PostmanImportService>((ref) {
  return PostmanImportService(ref.read(storageServiceProvider));
});

/// 导出服务 Provider（单例）
final postmanExportServiceProvider = Provider<PostmanExportService>((ref) {
  return PostmanExportService(ref.read(storageServiceProvider));
});
