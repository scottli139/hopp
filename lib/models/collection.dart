import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'auth_config.dart';
import 'http_request.dart';
import 'pre_request_step.dart';

part 'collection.freezed.dart';
part 'collection.g.dart';

/// Collection 模型 - 扁平化存储
///
/// 层级关系通过 [parentId] 字段建立，不再使用嵌套的 children 列表
/// 这种设计简化了数据一致性管理和 UI 渲染逻辑
@freezed
@HiveType(typeId: 3)
class Collection with _$Collection {
  const Collection._();

  const factory Collection({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) String? description,

    /// 父集合 ID，null 表示根集合
    @HiveField(3) String? parentId,

    /// 已废弃：子集合列表，现在使用扁平化存储，通过 parentId 查询
    /// 保留字段以保持向后兼容，但不再使用
    @HiveField(4) @Default([]) List<Collection> children,
    @HiveField(5) @Default([]) List<HttpRequest> requests,
    @HiveField(6) @Default(0) int sortOrder,
    @HiveField(7) @Default(false) bool isExpanded,

    /// 集合级默认 Auth 配置（F8.1；type = inherit 时继续向上查找，
    /// 根集合的 inherit 等同于无认证）
    @HiveField(8) @Default(AuthConfig()) AuthConfig auth,

    /// 集合级默认预请求链（F8.2；被集合下请求继承，请求级非空时覆盖）
    @HiveField(9) @Default([]) List<PreRequestStep> preRequestChain,

    /// 收到 401 时自动重跑前置链（F8.2；随链一起按层继承）
    @HiveField(10) @Default(false) bool preRequestRetryOn401,
  }) = _Collection;

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);

  factory Collection.empty() => Collection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Collection',
      );

  /// 判断是否为文件夹类型
  /// 注意：由于使用扁平化存储，需要查询是否有子集合
  bool get isFolder => requests.isEmpty;
}
