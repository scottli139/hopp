/// Postman Collection v2.1 Schema Models
///
/// 用于导入/导出 Postman Collection 和 Environment。
/// 遵循 Postman Collection Format v2.1 规范。
///
/// 参考: https://schema.getpostman.com/json/collection/v2.1.0/
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'postman_schema.freezed.dart';
part 'postman_schema.g.dart';

/// Postman Collection 版本
enum PostmanVersion {
  v2_0('2.0.0'),
  v2_1('2.1.0');

  final String value;
  const PostmanVersion(this.value);
}

/// Postman Collection 根对象
@freezed
class PostmanCollection with _$PostmanCollection {
  const factory PostmanCollection({
    required PostmanInfo info,
    required List<PostmanItem> item,
    List<PostmanVariable>? variable,
  }) = _PostmanCollection;

  factory PostmanCollection.fromJson(Map<String, dynamic> json) =>
      _$PostmanCollectionFromJson(json);
}

/// Collection 信息
@freezed
class PostmanInfo with _$PostmanInfo {
  const factory PostmanInfo({
    required String name,
    String? description,
    String? version,
    // ignore: invalid_annotation_target
    @JsonKey(name: '_postman_id') String? postmanId,
    String? schema,
  }) = _PostmanInfo;

  factory PostmanInfo.fromJson(Map<String, dynamic> json) =>
      _$PostmanInfoFromJson(json);
}

/// Collection 条目（可以是请求或文件夹）
@freezed
class PostmanItem with _$PostmanItem {
  const factory PostmanItem({
    required String name,
    PostmanRequest? request,
    List<PostmanItem>? item,
    List<PostmanResponse>? response,
    String? description,
  }) = _PostmanItem;

  factory PostmanItem.fromJson(Map<String, dynamic> json) =>
      _$PostmanItemFromJson(json);
}

/// Postman 请求
@freezed
class PostmanRequest with _$PostmanRequest {
  const factory PostmanRequest({
    required String method,
    required PostmanUrl url,
    List<PostmanHeader>? header,
    PostmanBody? body,
    String? description,
  }) = _PostmanRequest;

  factory PostmanRequest.fromJson(Map<String, dynamic> json) =>
      _$PostmanRequestFromJson(json);
}

/// URL 对象
@freezed
class PostmanUrl with _$PostmanUrl {
  const factory PostmanUrl({
    required String raw,
    String? protocol,
    @Default([]) List<String> host,
    @Default([]) List<String> path,
    List<PostmanQueryParam>? query,
  }) = _PostmanUrl;

  factory PostmanUrl.fromJson(Map<String, dynamic> json) =>
      _$PostmanUrlFromJson(json);
}

/// 查询参数
@freezed
class PostmanQueryParam with _$PostmanQueryParam {
  const factory PostmanQueryParam({
    required String key,
    String? value,
    @Default(true) bool enabled,
  }) = _PostmanQueryParam;

  factory PostmanQueryParam.fromJson(Map<String, dynamic> json) =>
      _$PostmanQueryParamFromJson(json);
}

/// 请求头
@freezed
class PostmanHeader with _$PostmanHeader {
  const factory PostmanHeader({
    required String key,
    required String value,
    @Default(true) bool enabled,
    String? description,
  }) = _PostmanHeader;

  factory PostmanHeader.fromJson(Map<String, dynamic> json) =>
      _$PostmanHeaderFromJson(json);
}

/// 请求体
@freezed
class PostmanBody with _$PostmanBody {
  const factory PostmanBody({
    required String mode,
    String? raw,
    List<PostmanUrlEncoded>? urlencoded,
    List<PostmanFormData>? formdata,
    PostmanGraphQL? graphql,
    PostmanBodyOptions? options,
  }) = _PostmanBody;

  factory PostmanBody.fromJson(Map<String, dynamic> json) =>
      _$PostmanBodyFromJson(json);
}

/// Body 选项
@freezed
class PostmanBodyOptions with _$PostmanBodyOptions {
  const factory PostmanBodyOptions({
    PostmanRawOptions? raw,
  }) = _PostmanBodyOptions;

  factory PostmanBodyOptions.fromJson(Map<String, dynamic> json) =>
      _$PostmanBodyOptionsFromJson(json);
}

/// Raw 选项
@freezed
class PostmanRawOptions with _$PostmanRawOptions {
  const factory PostmanRawOptions({
    String? language,
  }) = _PostmanRawOptions;

  factory PostmanRawOptions.fromJson(Map<String, dynamic> json) =>
      _$PostmanRawOptionsFromJson(json);
}

/// URL 编码表单数据
@freezed
class PostmanUrlEncoded with _$PostmanUrlEncoded {
  const factory PostmanUrlEncoded({
    required String key,
    String? value,
    @Default(true) bool enabled,
    String? type,
  }) = _PostmanUrlEncoded;

  factory PostmanUrlEncoded.fromJson(Map<String, dynamic> json) =>
      _$PostmanUrlEncodedFromJson(json);
}

/// Form Data 条目
@freezed
class PostmanFormData with _$PostmanFormData {
  const factory PostmanFormData({
    required String key,
    String? value,
    String? type,
    String? src,
    @Default(true) bool enabled,
  }) = _PostmanFormData;

  factory PostmanFormData.fromJson(Map<String, dynamic> json) =>
      _$PostmanFormDataFromJson(json);
}

/// GraphQL 查询
@freezed
class PostmanGraphQL with _$PostmanGraphQL {
  const factory PostmanGraphQL({
    required String query,
    String? variables,
  }) = _PostmanGraphQL;

  factory PostmanGraphQL.fromJson(Map<String, dynamic> json) =>
      _$PostmanGraphQLFromJson(json);
}

/// 响应（用于导出）
@freezed
class PostmanResponse with _$PostmanResponse {
  const factory PostmanResponse({
    required String name,
    required PostmanRequest originalRequest,
    required String status,
    required int code,
    String? body,
    List<PostmanHeader>? header,
  }) = _PostmanResponse;

  factory PostmanResponse.fromJson(Map<String, dynamic> json) =>
      _$PostmanResponseFromJson(json);
}

/// 变量
@freezed
class PostmanVariable with _$PostmanVariable {
  const factory PostmanVariable({
    required String key,
    String? value,
    String? type,
    @Default(true) bool enabled,
  }) = _PostmanVariable;

  factory PostmanVariable.fromJson(Map<String, dynamic> json) =>
      _$PostmanVariableFromJson(json);
}

/// Postman Environment
@freezed
class PostmanEnvironment with _$PostmanEnvironment {
  const factory PostmanEnvironment({
    required String name,
    String? id,
    // ignore: invalid_annotation_target
    @JsonKey(name: '_postman_variable_scope') String? scope,
    List<PostmanEnvironmentValue>? values,
  }) = _PostmanEnvironment;

  factory PostmanEnvironment.fromJson(Map<String, dynamic> json) =>
      _$PostmanEnvironmentFromJson(json);
}

/// Environment 变量值
@freezed
class PostmanEnvironmentValue with _$PostmanEnvironmentValue {
  const factory PostmanEnvironmentValue({
    required String key,
    String? value,
    @Default(true) bool enabled,
    String? type,
  }) = _PostmanEnvironmentValue;

  factory PostmanEnvironmentValue.fromJson(Map<String, dynamic> json) =>
      _$PostmanEnvironmentValueFromJson(json);
}

/// PostmanItem 扩展方法
extension PostmanItemExtension on PostmanItem {
  /// 判断是否为文件夹（包含子 item）
  bool get isFolder => item != null && item!.isNotEmpty;

  /// 判断是否为请求
  bool get isRequest => request != null;
}
