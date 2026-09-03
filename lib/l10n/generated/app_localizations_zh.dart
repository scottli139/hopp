// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Hopp';

  @override
  String get appDescription => '轻量级跨平台 API 测试工具';

  @override
  String get common_ok => '确定';

  @override
  String get common_cancel => '取消';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_edit => '编辑';

  @override
  String get common_create => '创建';

  @override
  String get common_close => '关闭';

  @override
  String get common_send => '发送';

  @override
  String get common_loading => '加载中...';

  @override
  String get common_error => '错误';

  @override
  String get common_success => '成功';

  @override
  String get sidebar_collections => '集合';

  @override
  String get sidebar_newCollection => '新建集合';

  @override
  String get sidebar_newFolder => '新建文件夹';

  @override
  String get sidebar_newRequest => '新建请求';

  @override
  String get sidebar_import => '导入';

  @override
  String get sidebar_export => '导出';

  @override
  String get request_params => '参数';

  @override
  String get request_headers => '请求头';

  @override
  String get request_body => '请求体';

  @override
  String get request_auth => '认证';

  @override
  String get request_urlPlaceholder => '输入 URL';

  @override
  String get request_namePlaceholder => '请求名称';

  @override
  String get request_noParams => '无参数';

  @override
  String get request_noHeaders => '无请求头';

  @override
  String get request_noBody => '无请求体';

  @override
  String get response_body => '响应体';

  @override
  String get response_headers => '响应头';

  @override
  String get response_cookies => 'Cookies';

  @override
  String get response_status => '状态';

  @override
  String get response_time => '时间';

  @override
  String get response_size => '大小';

  @override
  String get response_copy => '复制';

  @override
  String get response_save => '保存';

  @override
  String get response_noResponse => '发送请求以查看响应';

  @override
  String get settings_title => '设置';

  @override
  String get settings_appearance => '外观';

  @override
  String get settings_theme => '主题';

  @override
  String get settings_themeHint => '跟随系统或手动切换';

  @override
  String get settings_themeLight => '浅色';

  @override
  String get settings_themeDark => '深色';

  @override
  String get settings_themeSystem => '跟随系统';

  @override
  String get settings_language => '语言';

  @override
  String get settings_languageHint => '界面显示语言，切换即时生效';

  @override
  String get settings_uiScale => '界面缩放';

  @override
  String get settings_uiScaleHint => '全局文字缩放，适配 HiDPI 屏幕';

  @override
  String get common_system => '跟随系统';

  @override
  String get settings_english => '英文';

  @override
  String get settings_chinese => '中文';

  @override
  String get settings_editor => '编辑器';

  @override
  String get settings_fontSize => '字体大小';

  @override
  String get settings_fontFamily => '字体';

  @override
  String get settings_network => '网络';

  @override
  String get settings_timeout => '超时 (毫秒)';

  @override
  String get settings_followRedirects => '跟随重定向';

  @override
  String get settings_validateCertificates => '验证证书';

  @override
  String get status_ready => '就绪';

  @override
  String get status_sending => '发送中...';

  @override
  String get status_error => '错误';

  @override
  String sidebar_error(Object err) {
    return '错误：$err';
  }

  @override
  String get sidebar_themeSystem => '系统主题';

  @override
  String get sidebar_themeLight => '浅色主题';

  @override
  String get sidebar_themeDark => '深色主题';

  @override
  String get sidebar_aiSettings => 'AI 设置';

  @override
  String get sidebar_searchHint => '筛选…';

  @override
  String get sidebar_emptyTitle => '还没有集合';

  @override
  String get sidebar_emptySubtitle => '用集合组织你的 API 请求';

  @override
  String get sidebar_createCollection => '新建集合';

  @override
  String get sidebar_rename => '重命名';

  @override
  String get sidebar_deleteRequestTitle => '删除请求';

  @override
  String sidebar_deleteRequestBody(Object name) {
    return '确定要删除“$name”吗？此操作无法撤销。';
  }

  @override
  String get sidebar_addRequest => '添加请求';

  @override
  String get sidebar_addFolder => '添加文件夹';

  @override
  String get sidebar_folderNameHint => '输入文件夹名称';

  @override
  String get sidebar_collectionNameHint => '输入集合名称';

  @override
  String get sidebar_deleteCollectionTitle => '删除集合';

  @override
  String sidebar_deleteCollectionBody(Object name) {
    return '确定要删除“$name”吗？此操作无法撤销。';
  }

  @override
  String get sidebar_importMenu => '导入…';

  @override
  String get sidebar_refresh => '刷新';

  @override
  String get sidebar_about => '关于';

  @override
  String get sidebar_aboutTagline => '轻快直达你的 API';

  @override
  String get sidebar_aboutVersion => '版本';

  @override
  String get sidebar_aboutPlatform => '平台';

  @override
  String get sidebar_aboutFooter => '由 AI 驱动 · 基于 Flutter 构建';

  @override
  String get sidebar_aboutCopyright => '© 2026 Hopp. 保留所有权利。';

  @override
  String get sidebar_aboutMoreInfo => '更多信息';

  @override
  String get viewer_copied => '已复制到剪贴板';

  @override
  String get viewer_beautified => '代码已格式化';

  @override
  String get viewer_beautifyFailed => '代码格式化失败';

  @override
  String viewer_sizeLines(Object lines, Object size) {
    return '$size • $lines 行';
  }

  @override
  String get viewer_hideTimestamps => '隐藏时间戳注释';

  @override
  String get viewer_showTimestamps => '显示时间戳注释';

  @override
  String get viewer_beautify => '格式化';

  @override
  String get viewer_modePerformance => '性能模式';

  @override
  String get viewer_modeFull => '完整模式';

  @override
  String viewer_showingLines(Object displayed, Object total) {
    return '已显示 $total 行中的 $displayed 行';
  }

  @override
  String viewer_loadMore(Object remaining) {
    return '再加载 $remaining 行';
  }

  @override
  String get viewer_loadAll => '加载全部';

  @override
  String get viewer_largeResponseTitle => '响应过大';

  @override
  String viewer_largeResponseBody(Object size) {
    return '此响应大小为 $size，可能导致性能问题。要使用性能模式查看吗？';
  }

  @override
  String get viewer_viewFull => '查看完整响应';

  @override
  String get viewer_performanceMode => '性能模式';

  @override
  String get editor_enterText => '输入文本…';

  @override
  String get ai_configNotLoaded => 'AI 配置未加载，请稍后重试';

  @override
  String get ai_modelNotConfigured => '请先在设置中配置本地模型（模型名）';

  @override
  String get ai_noResponseSample => '请先在 Tests 运行或发送请求';

  @override
  String ai_httpError(Object message) {
    return '模型服务错误：$message';
  }

  @override
  String ai_callFailed(Object error) {
    return 'AI 调用失败：$error';
  }

  @override
  String get ai_connectionFailed => '未检测到本地模型服务，请确认 Ollama / LM Studio 已启动';

  @override
  String ai_connectionFailedDetail(Object detail) {
    return '未检测到本地模型服务，请确认 Ollama / LM Studio 已启动（$detail）';
  }

  @override
  String get ai_timeout => '本地模型响应超时：可能是首次加载模型或机器负载较高，请重试';

  @override
  String ai_timeoutDetail(Object detail) {
    return '本地模型响应超时：可能是首次加载模型或机器负载较高，请重试（$detail）';
  }

  @override
  String get ai_responseError => '模型服务返回异常，请稍后重试';

  @override
  String ai_responseErrorDetail(Object detail) {
    return '模型服务返回异常：$detail';
  }

  @override
  String get ai_requestFailed => '请求失败';

  @override
  String get ai_responseNotJsonObject => '响应体不是 JSON 对象';

  @override
  String get ai_choicesEmpty => 'choices 为空';

  @override
  String get ai_choiceMessageMalformed => 'choices[0].message 结构不符';

  @override
  String get ai_choiceContentEmpty => 'choices[0].message.content 为空';

  @override
  String get ai_parseError => 'AI 返回格式异常，请重试';

  @override
  String request_preRequestChainFailed(Object error) {
    return '预请求链执行失败：$error';
  }

  @override
  String get import_failed => '导入失败';

  @override
  String import_failedWithError(Object error) {
    return '导入失败: $error';
  }

  @override
  String get import_resolveConflictFailed => '解决冲突失败';

  @override
  String import_resolveConflictFailedWithError(Object error) {
    return '解决冲突失败: $error';
  }

  @override
  String get import_fileNotFound => '文件不存在';

  @override
  String get import_unknownFormat =>
      '无法识别文件格式，请确保是有效的 Postman Collection 或 Environment';

  @override
  String get import_emptyCollection => '导入的集合不包含任何请求';

  @override
  String import_invalidJson(Object error) {
    return '无法解析 JSON 文件: $error';
  }

  @override
  String import_invalidEnvironmentJson(Object error) {
    return '无法解析 Environment 文件: $error';
  }

  @override
  String get import_unsupportedVersion =>
      '不支持的 Postman Collection 版本: v1.0。请升级到 v2.0 或 v2.1 格式';

  @override
  String import_environmentSuccess(Object count, Object name) {
    return '环境「$name」导入成功（$count 个变量）';
  }

  @override
  String get import_existingCollectionNotFound => '无法找到现有集合';

  @override
  String get import_existingCollectionMissing => '现有集合不存在';

  @override
  String export_failedWithError(Object error) {
    return '导出失败: $error';
  }

  @override
  String export_collectionNotFound(Object id) {
    return '未找到集合：$id';
  }

  @override
  String get openapi_unknownFormat => '无法识别为 OpenAPI/Swagger 文档';

  @override
  String get openapi_missingPaths => '无法识别为 OpenAPI/Swagger 文档：缺少 paths';

  @override
  String get openapi_fetchEmpty => '拉取失败: 响应内容为空';

  @override
  String openapi_fetchFailed(Object error) {
    return '拉取失败: $error';
  }

  @override
  String get openapi_noOperations => '文档不包含任何可导入的接口';

  @override
  String get openapi_conflictResolveFailed => '冲突解决失败';

  @override
  String get openapi_noSource => '未提供导入来源（filePath / url / content 三选一）';

  @override
  String openapi_parseFailed(Object error) {
    return '解析失败: $error';
  }

  @override
  String get openapi_placeholderFormData => '表单字段由 schema 生成，请检查并填写';

  @override
  String get openapi_placeholderBody => '请求体由 schema 骨架生成，请检查并填写';

  @override
  String get openapi_authBearer => 'Bearer Token（请填写 token）';

  @override
  String get openapi_authBasic => 'Basic Auth（请填写用户名/密码）';

  @override
  String openapi_authApiKey(Object name, Object where) {
    return 'API Key（$where：$name——请填写 key）';
  }

  @override
  String get curl_emptyInput => '请输入 cURL 命令';

  @override
  String get curl_invalidCommand => '无效的 cURL 命令，必须以 \"curl\" 开头';

  @override
  String get curl_unknownError => '未知错误';

  @override
  String curl_parseFailed(Object error) {
    return '解析 cURL 命令失败: $error';
  }

  @override
  String curl_unsupportedOption(Object option) {
    return '不支持的选项: -$option';
  }

  @override
  String get collection_saveNoCollection => '无法创建或找到用于保存请求的集合';

  @override
  String get collection_notLoaded => '集合尚未加载完成';

  @override
  String collectionSettings_title(Object name) {
    return '$name · 设置';
  }

  @override
  String get collectionSettings_sectionHeader => '集合';

  @override
  String get collectionSettings_navGeneral => '常规';

  @override
  String get collectionSettings_navPreRequest => '预请求';

  @override
  String get collectionSettings_nameLabel => '名称';

  @override
  String get collectionSettings_descLabel => '描述';

  @override
  String get collectionSettings_descHint => '可选描述';

  @override
  String collectionSettings_inheritFrom(Object name) {
    return '当前继承自父集合「$name」。修改请到对应集合的设置。';
  }

  @override
  String collectionSettings_inheritNoAuth(Object name) {
    return '继承自父集合「$name」：No Auth。';
  }

  @override
  String get collectionSettings_rootInherit =>
      '根集合的 Inherit 等同于 No Auth，发送时不附加认证信息。';

  @override
  String get import_done => '完成';

  @override
  String get import_retry => '重试';

  @override
  String get import_back => '返回';

  @override
  String get import_importing => '导入中...';

  @override
  String get import_failedTitle => '导入失败';

  @override
  String get import_successTitle => '导入成功';

  @override
  String import_successRenamed(Object name) {
    return '集合已重命名为：$name';
  }

  @override
  String get import_successMerged => '集合已合并到现有集合';

  @override
  String import_successCount(Object count) {
    return '成功导入 $count 个请求';
  }

  @override
  String get import_dropZoneHint => '点击选择文件或拖放到此处';

  @override
  String get import_dropZoneSupport =>
      '支持 Postman Collection v2.0/v2.1 和 Environment';

  @override
  String get import_selectFile => '选择文件';

  @override
  String get import_parse => '解析';

  @override
  String import_importRequest(Object count) {
    return '导入 $count 个请求';
  }

  @override
  String import_importRequests(Object count) {
    return '导入 $count 个请求';
  }

  @override
  String get import_openCollection => '打开集合';

  @override
  String import_previewStats(Object selected, Object subCount, Object total) {
    return '已选 $selected / $total · 1 个集合 + $subCount 个子集合';
  }

  @override
  String get import_unknownError => '未知错误';

  @override
  String get import_selectCollection => '选择集合';

  @override
  String conflict_title(Object name) {
    return '「$name」已存在';
  }

  @override
  String get conflict_prompt => '请选择处理方式：';

  @override
  String get conflict_rename => '重命名导入';

  @override
  String conflict_renameSubtitle(Object name) {
    return '将导入的集合重命名为「$name (1)」';
  }

  @override
  String get conflict_overwrite => '覆盖现有';

  @override
  String get conflict_overwriteSubtitle => '用导入内容替换现有集合';

  @override
  String get conflict_merge => '合并集合';

  @override
  String get conflict_mergeSubtitle => '保留现有请求并添加新请求';

  @override
  String get conflict_skip => '跳过';

  @override
  String get conflict_skipSubtitle => '取消导入此集合';

  @override
  String get conflict_confirm => '确定';

  @override
  String get conflict_dialogTitle => '集合名称重复';

  @override
  String conflict_dialogMessage(Object name) {
    return '「$name」已存在，请选择处理方式：';
  }

  @override
  String get conflict_skipThis => '跳过此集合';

  @override
  String get conflict_applyToAll => '应用到所有冲突';

  @override
  String get export_loadFailed => '无法加载集合列表';

  @override
  String get export_exporting => '导出中...';

  @override
  String get export_exportingCollection => '正在导出集合...';

  @override
  String get export_successTitle => '导出成功';

  @override
  String get export_savedTo => '文件已保存到：';

  @override
  String get export_failedTitle => '导出失败';

  @override
  String get export_dialogTitle => '导出集合';

  @override
  String get export_formatHeader => '格式';

  @override
  String get export_formatPostman => 'Postman 集合';

  @override
  String get export_formatPostmanDesc1 => '与 Postman 及其他工具互操作。断言和预请求链';

  @override
  String get export_formatPostmanDescNot => '不';

  @override
  String get export_formatPostmanDesc2 => '会被包含（该格式无法表达）。';

  @override
  String get export_formatHoppDesc1 => '全保真：断言、预请求链、认证与变量管道。在 CI 中用 ';

  @override
  String get export_formatHoppDesc2 => ' 运行。';

  @override
  String get export_secretNotice1 => 'Secret 变量的值导出为空。在 CI 中通过 ';

  @override
  String get export_secretNotice2 => ' 或进程环境变量注入。';

  @override
  String get export_formatVersion => '格式版本';

  @override
  String get export_prettify => '美化 JSON 输出';

  @override
  String get export_prettifyHint => '使用缩进格式化，便于阅读';

  @override
  String get export_saveHoppTitle => '保存 Hopp CLI 集合';

  @override
  String get export_savePostmanTitle => '保存 Postman 集合';

  @override
  String get curl_importAndSend => '导入并发送';

  @override
  String get curl_commandLabel => 'cURL 命令';

  @override
  String get curl_paste => '粘贴';

  @override
  String get curl_emptyPreview => '解析后的请求将显示在这里';

  @override
  String get curl_parsing => '解析中...';

  @override
  String get curl_parseError => '解析错误';

  @override
  String get curl_parsedSuccess => '解析成功';

  @override
  String curl_warningCountOne(Object count) {
    return '$count 个警告';
  }

  @override
  String curl_warningCountMany(Object count) {
    return '$count 个警告';
  }

  @override
  String get curl_labelMethod => '方法';

  @override
  String get curl_labelUrl => 'URL';

  @override
  String curl_headersEnabled(Object count) {
    return '$count 个启用';
  }

  @override
  String get curl_labelBodyType => '请求体类型';

  @override
  String get curl_labelBodySize => '请求体大小';

  @override
  String curl_bodyBytes(Object count) {
    return '$count 字节';
  }

  @override
  String get curl_sslVerifyOff => 'SSL 验证：关';

  @override
  String get curl_followRedirectsOn => '跟随重定向：开';

  @override
  String get curl_warningsLabel => '警告：';

  @override
  String get curl_requestNameHint => '输入请求名称...';

  @override
  String get curl_noCollections => '没有可用集合，请先创建集合。';

  @override
  String get curl_saveToCollection => '保存到集合';

  @override
  String get curl_loadFailed => '加载集合失败';

  @override
  String get openapi_parsing => '正在解析 Spec…';

  @override
  String get openapi_importing => '导入中…';

  @override
  String get openapi_dropZoneHint => '点击选择 Spec 文件';

  @override
  String get openapi_dropZoneSupport =>
      '支持 .json / .yaml / .yml · OpenAPI 3.x · Swagger 2.0';

  @override
  String get openapi_orFromUrl => '或从 URL 导入';

  @override
  String get openapi_specUrlLabel => 'Spec URL';

  @override
  String get openapi_specUrlHint =>
      '机器可读地址（openapi.json / swagger.yaml），本地解析——数据不会离开你的机器。';

  @override
  String get openapi_headerLabel => '请求头';

  @override
  String get openapi_headerHint => '可选。仅用于本次拉取的一个自定义请求头（私有 Spec），不会保存。';

  @override
  String openapi_specSummary(Object opCount, Object tagCount, Object version) {
    return ' · OpenAPI $version · $tagCount 个标签 · $opCount 个接口';
  }

  @override
  String get openapi_serverLabel => ' · 服务器 ';

  @override
  String get openapi_searchHint => '搜索路径或名称…';

  @override
  String get openapi_selectAll => '全选';

  @override
  String get openapi_selectNone => '全不选';

  @override
  String get openapi_noMatch => '没有匹配的接口';

  @override
  String get openapi_noTag => '无标签';

  @override
  String get openapi_statRequests => '已导入请求';

  @override
  String get openapi_statPlaceholders => '占位符';

  @override
  String openapi_importedAs(Object name) {
    return '已导入为「$name」';
  }

  @override
  String openapi_mergedInto(Object name) {
    return '已合并到现有集合「$name」';
  }

  @override
  String get openapi_placeholdersHeader => '占位符（值来自 SCHEMA 骨架，而非 SPEC 示例）';

  @override
  String openapi_oauthNotice(Object schemes) {
    return 'OAuth2 / OpenID Connect 方案 $schemes 未自动配置。请到集合设置 → Auth 完成授权流程。';
  }

  @override
  String openapi_authConfigured(Object description) {
    return '已配置集合级认证：$description。';
  }

  @override
  String get curl_inputHint => '在此粘贴 cURL 命令...';

  @override
  String get curl_inputHintExample => '示例：';

  @override
  String get common_retry => '重试';

  @override
  String get common_show => '显示';

  @override
  String get common_hide => '隐藏';

  @override
  String get request_selectRequestTitle => '选择一个请求';

  @override
  String get request_selectRequestSubtitle => '从侧边栏选择请求，或新建一个请求';

  @override
  String request_unresolvedVariables(Object variables) {
    return '未解析的变量：$variables';
  }

  @override
  String get request_tabPreRequest => '预请求';

  @override
  String get request_tabAssertions => '断言';

  @override
  String get request_keyColumn => '键';

  @override
  String get request_valueColumn => '值';

  @override
  String get request_descriptionColumn => '描述';

  @override
  String get request_addNewRow => '添加新行';

  @override
  String get request_noBodyContent => '暂无请求体内容';

  @override
  String get request_selectBodyTypeHint => '选择请求体类型以添加内容';

  @override
  String get request_formDataComingSoon => 'form-data 编辑器（即将推出）';

  @override
  String get request_urlEncodedComingSoon => 'x-www-form-urlencoded 编辑器（即将推出）';

  @override
  String get request_bodySectionTitle => '请求体';

  @override
  String get request_selectFile => '选择文件';

  @override
  String get request_chooseFile => '选择文件';

  @override
  String get request_graphqlComingSoon => 'GraphQL 编辑器（即将推出）';

  @override
  String request_inheritSummaryNoAuth(Object name) {
    return '继承自集合「$name」：No Auth，发送时不附加认证信息。';
  }

  @override
  String request_inheritSummary(Object authType, Object name) {
    return '当前继承自集合「$name」：$authType。修改请到集合设置。';
  }

  @override
  String get request_sslVerification => '启用 SSL 证书验证';

  @override
  String get request_sslVerificationHint => '验证服务器的 SSL 证书链';

  @override
  String get request_sslDisableNote => '关闭此选项可允许自签名证书，或在测试时绕过证书错误。';

  @override
  String get request_redirectsSection => '重定向';

  @override
  String get request_followRedirects => '跟随重定向';

  @override
  String get request_followRedirectsHint => '自动跟随 HTTP 3xx 重定向';

  @override
  String get request_maxRedirects => '最大重定向次数';

  @override
  String get request_maxRedirectsHint => '限制跟随的重定向次数（0 = 不限制）';

  @override
  String get request_comingSoonSection => '即将推出';

  @override
  String get request_timeoutTitle => '请求超时';

  @override
  String get request_timeoutHint => '设置请求超时时长';

  @override
  String get request_savedToCollection => '请求已保存到集合';

  @override
  String get request_saveFailed => '保存请求失败';

  @override
  String get request_saveFailedCollection => '保存失败：集合错误，请重试。';

  @override
  String get request_headerDescAccept => '响应可接受的媒体类型';

  @override
  String get request_headerDescAcceptCharset => '可接受的字符集';

  @override
  String get request_headerDescAcceptEncoding => '可接受的内容编码（gzip、deflate、br）';

  @override
  String get request_headerDescAcceptLanguage => '可接受的自然语言列表';

  @override
  String get request_headerDescAuthorization => '认证凭据（Bearer token、Basic auth）';

  @override
  String get request_headerDescCacheControl => '缓存机制指令';

  @override
  String get request_headerDescConnection => '当前连接的控制选项（keep-alive）';

  @override
  String get request_headerDescContentLength => '请求体的字节长度';

  @override
  String get request_headerDescContentType => '请求体的 MIME 类型（application/json）';

  @override
  String get request_headerDescCookie => '服务器此前发送的 HTTP Cookie';

  @override
  String get request_headerDescHost => '服务器域名（及可选端口）';

  @override
  String get request_headerDescOrigin => '指示请求的来源';

  @override
  String get request_headerDescReferer => '上一个页面的地址';

  @override
  String get request_headerDescUserAgent => '客户端的 User-Agent 字符串';

  @override
  String get request_headerDescXRequestedWith => '用于标识 AJAX 请求';

  @override
  String get assertion_targetStatus => '状态码';

  @override
  String get assertion_targetHeader => '响应头';

  @override
  String get assertion_targetBody => '响应体文本';

  @override
  String get assertion_targetJsonPath => 'JSONPath';

  @override
  String get assertion_targetResponseTime => '响应时间';

  @override
  String get assertion_title => '响应断言';

  @override
  String get assertion_noteEvaluated => '每次发送后求值。';

  @override
  String get assertion_noteExpectedPrefix => '期望值支持 ';

  @override
  String get assertion_noteExpectedSuffix => '。';

  @override
  String get assertion_add => '添加断言';

  @override
  String get assertion_colTarget => '目标';

  @override
  String get assertion_colNamePath => '名称 / 路径';

  @override
  String get assertion_colOperator => '操作符';

  @override
  String get assertion_colExpected => '期望值';

  @override
  String get assertion_headerNameHint => 'Header 名称';

  @override
  String get assertion_expectedHint => '期望值';

  @override
  String get assertion_hintPrefix => '操作符按目标过滤——例如 ';

  @override
  String get assertion_hintNoExpected => ' 无需期望值；';

  @override
  String get assertion_hintComparison => ' 适用于状态码 / 响应时间。响应时间以毫秒为单位。';

  @override
  String get assertion_emptyTitle => '暂无断言';

  @override
  String get assertion_emptySubtitle => '添加断言以在每次发送后校验响应';

  @override
  String get auth_typeSectionTitle => '认证类型';

  @override
  String get auth_typeInherit => '继承';

  @override
  String get auth_typeNone => '无认证';

  @override
  String get auth_typeBearer => 'Bearer Token';

  @override
  String get auth_typeBasic => 'Basic Auth';

  @override
  String get auth_typeApiKey => 'API Key';

  @override
  String get auth_inheritDesc => '跟随所属集合的 Auth 配置。';

  @override
  String get auth_inheritNotFound => '继承链上未找到认证配置，发送时不附加认证信息。';

  @override
  String get auth_noneDesc => '不附加认证信息，并阻断对集合配置的继承。';

  @override
  String get auth_bearerDesc =>
      '发送时自动附加 Authorization: Bearer <token>，Headers 中同名项将被覆盖。';

  @override
  String get auth_tokenLabel => 'Token';

  @override
  String get auth_basicDesc =>
      '发送时自动附加 Authorization: Basic base64(user:pass)。';

  @override
  String get auth_username => '用户名';

  @override
  String get auth_password => '密码';

  @override
  String get auth_apiKeyDesc => '自定义 key 注入 Header 或 Query Params。';

  @override
  String get auth_keyLabel => 'Key';

  @override
  String get auth_addTo => '添加到';

  @override
  String get auth_addToHeader => '请求头';

  @override
  String get auth_addToQuery => '查询参数';

  @override
  String auth_variableHint(Object example, Object variable) {
    return '所有字段支持 $variable 与转换管道（如 $example）。';
  }

  @override
  String get prerequest_title => '前置链';

  @override
  String get prerequest_subtitle => '发送本请求前依次执行；步骤产出的变量写入「本地」作用域，仅本次会话有效，不污染环境';

  @override
  String get prerequest_addStep => '添加步骤';

  @override
  String get prerequest_testRun => '试运行';

  @override
  String get prerequest_emptyTitle => '暂无前置步骤';

  @override
  String prerequest_emptyHint(Object token) {
    return '典型场景：先执行「登录」请求，从响应提取 $token';
  }

  @override
  String get prerequest_selectRequest => '选择请求…';

  @override
  String get prerequest_requestDeleted => '引用的请求已被删除';

  @override
  String get prerequest_deleteStep => '删除步骤';

  @override
  String get prerequest_extractHeader => 'EXTRACT · 从响应提取变量';

  @override
  String get prerequest_sourceJsonPath => '响应体 · JSONPath';

  @override
  String get prerequest_sourceHeader => '响应头';

  @override
  String get prerequest_sourceRegex => '响应体 · Regex';

  @override
  String get prerequest_deleteRule => '删除规则';

  @override
  String get prerequest_addRule => '添加提取规则';

  @override
  String get prerequest_policyTitle => '过期策略';

  @override
  String get prerequest_retry401Hint => '收到 401 时自动重跑前置链（关闭 = 发送后手动重发）';

  @override
  String get prerequest_scopeTooltip => '链产出变量写入本地作用域（会话级），不污染环境';

  @override
  String get prerequest_scopeLocal => '变量作用域：本地';

  @override
  String get prerequest_resultTitle => '试运行结果';

  @override
  String get prerequest_allSucceeded => '全部步骤成功';

  @override
  String get prerequest_someStepsFailed => '有步骤失败';

  @override
  String get prerequest_noVariables => '未产出变量（检查提取规则）';

  @override
  String prerequest_stepN(Object index) {
    return '步骤 $index';
  }

  @override
  String prerequest_missingValue(Object path, Object variable) {
    return '$path → $variable：未取到值';
  }

  @override
  String get fx_tooltip => '变量预览与转换函数';

  @override
  String get fx_resolvedPreview => '解析预览';

  @override
  String get fx_insertDynamicVariable => '插入动态变量';

  @override
  String get fx_insertTransform => '插入转换函数';

  @override
  String fx_emptyHint(Object variable) {
    return '输入 $variable 后可在此预览解析结果';
  }

  @override
  String get fx_undefined => '（未定义）';

  @override
  String get fx_transformFailed => '（转换失败）';

  @override
  String get fx_dateAddFormatError => '格式：[+-]整数+单位（s/m/h/d/w），如 -7d';

  @override
  String get fx_dateAddUnitHint =>
      '单位：s 秒 / m 分 / h 时 / d 天 / w 周；基准为 10 位秒 / 13 位毫秒 epoch。';

  @override
  String get fx_floorHour => 'hour · 本小时零点';

  @override
  String get fx_floorDay => 'day · 今天零点';

  @override
  String get fx_floorWeek => 'week · 本周一零点';

  @override
  String get fx_floorMonth => 'month · 本月 1 号零点';

  @override
  String get fx_dateFloorHint => '本地时区取整；基准为 10 位秒 / 13 位毫秒 epoch，输出同单位。';

  @override
  String get fx_insert => '插入';

  @override
  String fx_aesKeyHint(Object sample) {
    return '$sample · 16/24/32 字节';
  }

  @override
  String fx_aesIvHint(Object sample) {
    return '$sample · cbc 需 16 字节';
  }

  @override
  String fx_paramVariableHint(Object variable) {
    return '参数支持 $variable 引用。';
  }

  @override
  String get response_noResponseYet => '暂无响应';

  @override
  String get response_copyResponse => '复制响应';

  @override
  String get response_saveResponse => '保存响应';

  @override
  String get response_noResponseTitle => '暂无响应';

  @override
  String get response_noHeadersTitle => '暂无响应头';

  @override
  String get response_noHeadersHint => '发送请求以查看响应头';

  @override
  String get response_headerNameColumn => '名称';

  @override
  String get response_cookiesComingSoon => 'Cookie 管理功能即将推出';

  @override
  String get response_noRequestTitle => '暂无请求';

  @override
  String get response_noRequestHint => '创建请求以查看详情';

  @override
  String response_headersCount(Object count) {
    return '请求头（$count）';
  }

  @override
  String response_bodyWithType(Object type) {
    return '请求体（$type）';
  }

  @override
  String get response_urlScheme => '协议';

  @override
  String get response_urlHost => '主机';

  @override
  String get response_urlPort => '端口';

  @override
  String get response_urlPath => '路径';

  @override
  String response_customCount(Object count) {
    return '$count 个自定义';
  }

  @override
  String get response_autoAddedHeaders => '自动添加的请求头';

  @override
  String get response_autoBadge => '自动';

  @override
  String get response_totalRequestTime => '请求总耗时';

  @override
  String get response_phaseBreakdown => '阶段耗时明细';

  @override
  String get response_dnsLookup => 'DNS 查询';

  @override
  String get response_tcpConnect => 'TCP 连接';

  @override
  String get response_tlsHandshake => 'TLS 握手';

  @override
  String get response_ttfb => 'TTFB（首字节时间）';

  @override
  String get response_download => '下载';

  @override
  String get response_timeline => '时间线';

  @override
  String response_assertionsPassed(Object passed, Object total) {
    return '$passed/$total 通过';
  }

  @override
  String get response_tabRequest => '请求';

  @override
  String get response_tabTests => '测试';

  @override
  String get response_tabTiming => '耗时';

  @override
  String get response_tabCertificate => '证书';

  @override
  String get response_noAssertionsConfigured => '未配置断言——请在「断言」页签中添加。';

  @override
  String get response_assertionsNotRun => '尚未运行——发送请求以求值断言。';

  @override
  String get response_assertionDisabled => '已禁用';

  @override
  String response_expectedValueAt(Object arg) {
    return '$arg 处的值';
  }

  @override
  String response_expectedHeader(Object arg) {
    return '响应头 \"$arg\"';
  }

  @override
  String get response_expectedPresent => '存在';

  @override
  String get response_expectedLabel => '期望值';

  @override
  String get response_actualLabel => '实际值';

  @override
  String get response_resolvedLabel => '解析结果';

  @override
  String get response_certValid => '证书有效';

  @override
  String get response_certExpired => '证书已过期';

  @override
  String response_certDaysRemaining(Object days) {
    return '剩余 $days 天';
  }

  @override
  String response_certExpiredOn(Object date) {
    return '已于 $date 过期';
  }

  @override
  String get response_certDetails => '证书详情';

  @override
  String get response_certSubject => '使用者';

  @override
  String get response_certIssuer => '颁发者';

  @override
  String get response_certValidFrom => '有效期自';

  @override
  String get response_certValidTo => '有效期至';

  @override
  String get response_certSignatureAlgorithm => '签名算法';

  @override
  String get response_certSerialNumber => '序列号';

  @override
  String get response_certSha256 => 'SHA-256 指纹';

  @override
  String get response_certPublicKeyAlgorithm => '公钥算法';

  @override
  String get response_certPublicKeyLength => '公钥长度';

  @override
  String get response_certSan => '使用者备用名称';

  @override
  String response_certBits(Object bits) {
    return '$bits 位';
  }

  @override
  String get response_certChain => '证书链';

  @override
  String response_certIssuedBy(Object issuer) {
    return '颁发者：$issuer';
  }

  @override
  String get response_copiedToClipboard => '已复制到剪贴板';

  @override
  String get env_selectTooltip => '选择环境';

  @override
  String get env_none => '无环境';

  @override
  String env_unresolvedVariables(Object variables) {
    return '未解析的变量：$variables';
  }

  @override
  String get env_manage => '管理环境';

  @override
  String get env_globals => '全局变量';

  @override
  String env_footerHint(Object varRef) {
    return '在 URL、请求头和请求体中以 $varRef 引用变量 · secret 值只写不可读';
  }

  @override
  String env_variableCount(Object count, Object varRef) {
    return '$count 个变量 · 以 $varRef 引用';
  }

  @override
  String get env_globalsHint => '在所有环境间共享 · 可被环境变量覆盖';

  @override
  String get env_sectionEnvironments => '环境';

  @override
  String get env_sectionShared => '共享';

  @override
  String get env_newEnvironment => '新建环境';

  @override
  String get env_nameHint => '名称';

  @override
  String get env_deleteTooltip => '删除环境';

  @override
  String get env_emptyTitle => '还没有变量';

  @override
  String env_emptySubtitle(Object varRef) {
    return '添加一个变量，以 $varRef 引用';
  }

  @override
  String get env_addVariable => '添加变量';

  @override
  String get env_headerKey => '键';

  @override
  String get env_headerValue => '值';

  @override
  String get env_headerType => '类型';

  @override
  String get env_keyHint => '键';

  @override
  String get env_valueHint => '值';

  @override
  String get env_showValue => '显示值';

  @override
  String get env_hideValue => '隐藏值';

  @override
  String get env_removeVariable => '移除变量';

  @override
  String get ai_presetCustom => '自定义';

  @override
  String get ai_settingsTitle => 'AI 设置';

  @override
  String get ai_notReady => '未启用本地 AI 或未配置模型';

  @override
  String get ai_openSettings => '打开设置';

  @override
  String get ai_enableLocal => '启用本地 AI';

  @override
  String get ai_providerPreset => 'Provider 预设';

  @override
  String get ai_baseUrl => 'Base URL';

  @override
  String get ai_model => '模型';

  @override
  String get ai_modelHint => '手填，如 llama3.1:8b';

  @override
  String get ai_apiKey => 'API Key';

  @override
  String get ai_apiKeyHint => '留空即可';

  @override
  String get ai_apiKeyNote => '本地模型通常无需 Key，留空即可；仅 Tier 2 云端使用';

  @override
  String get ai_connIdle => '尚未检查连接';

  @override
  String get ai_connChecking => '正在检查连接…';

  @override
  String get ai_connected => '已连接';

  @override
  String get ai_checkConnection => '检查连接';

  @override
  String get ai_explainTitle => '解释响应';

  @override
  String get ai_noResponseToExplain => '暂无响应可解释';

  @override
  String get ai_regenerate => '重新生成';

  @override
  String get ai_explaining => '正在解释…（本地模型可能需要 10–30 秒）';

  @override
  String get ai_retry => '重试';

  @override
  String get ai_buildTitle => '自然语言建请求';

  @override
  String get ai_overwriteTitle => '覆盖当前请求内容？';

  @override
  String get ai_overwriteMessage =>
      '当前请求已有内容，填入草稿将覆盖 URL、Params、Headers 与 Body。';

  @override
  String get ai_overwrite => '覆盖';

  @override
  String get ai_generating => '正在生成…（本地模型可能需要 10–30 秒）';

  @override
  String get ai_buildDescHint =>
      '描述你想创建的请求，例如：POST 创建用户，JSON body 含 name 和 email，需要认证';

  @override
  String get ai_buildDraftNote => '生成的是草稿，填入编辑器后可继续修改；字段取值仅来自你的描述';

  @override
  String get ai_zeroRows => '0 行';

  @override
  String get ai_sectionParams => '参数';

  @override
  String get ai_sectionHeaders => '请求头';

  @override
  String ai_sectionBody(Object type) {
    return '请求体 · $type';
  }

  @override
  String get ai_applyDraft => '填入当前请求';

  @override
  String get ai_generate => '生成';

  @override
  String get ai_generateButton => 'AI 生成';

  @override
  String get ai_needResponseSample => '请先在 Tests 运行或发送请求';

  @override
  String get ai_genAssertionsTitle => 'AI 生成断言';

  @override
  String ai_genSelected(Object checked, Object total) {
    return '基于最近一次响应生成 · 已选 $checked/$total 条';
  }

  @override
  String ai_genDiscarded(Object count) {
    return '已丢弃 $count 条不合规建议';
  }

  @override
  String ai_addChecked(Object count) {
    return '添加 $count 条';
  }

  @override
  String get ai_generatingAssertions => '正在生成断言…（本地模型可能需要 10–30 秒）';

  @override
  String get ai_noSuggestions => '没有生成可用的断言建议';

  @override
  String get ai_colTarget => '目标';

  @override
  String get ai_colPath => '路径';

  @override
  String get ai_colOperator => '运算符';

  @override
  String get ai_colExpected => '期望值';

  @override
  String get ai_headerNameHint => '请求头名称';

  @override
  String get ai_expectedValueHint => '期望值';

  @override
  String get main_emptyTitle => '还没有请求';

  @override
  String get main_emptySubtitle => '创建第一个请求，开始使用';

  @override
  String get main_createRequest => '创建请求';

  @override
  String get main_emptyShortcutHint => '或按 Cmd+N';

  @override
  String get main_selectTab => '选择一个标签页开始';

  @override
  String get about_title => '关于';

  @override
  String get about_tagline => '轻松直达你的 API';

  @override
  String get about_version => '版本';

  @override
  String get about_description => '简介';

  @override
  String get about_descriptionContent =>
      '一款基于 Flutter 构建的轻量级跨平台 API 测试工具。Hopp 让 API 测试简单、快速、有趣。';

  @override
  String get about_features => '功能特性';

  @override
  String get about_featureLightweight => '🔥 轻量快速';

  @override
  String get about_featureCrossPlatform => '💻 跨平台（macOS、Windows、Linux）';

  @override
  String get about_featureHttp => '📝 完整 HTTP 请求支持';

  @override
  String get about_featureCollections => '📦 集合管理';

  @override
  String get about_featureTabs => '📑 多标签页';

  @override
  String get about_featureDarkMode => '🌓 深色模式支持';

  @override
  String get about_featureLanguages => '🌍 多语言支持';

  @override
  String get about_featureLocal => '🔒 本地数据存储';

  @override
  String get about_techStack => '技术栈';

  @override
  String get about_links => '链接';

  @override
  String get about_githubRepo => 'GitHub 仓库';

  @override
  String get about_reportIssues => '反馈问题';

  @override
  String get about_reportIssuesSubtitle => '提交 Bug 报告和功能建议';

  @override
  String get about_contribute => '参与贡献';

  @override
  String get about_contributeSubtitle => '帮助 Hopp 变得更好';

  @override
  String get about_builtWith => '由 Hopp 团队倾心打造';

  @override
  String get about_copyright => '© 2026 Hopp. 保留所有权利。';

  @override
  String get about_poweredBy => 'AI 驱动 · Flutter 构建';

  @override
  String get gallery_title => '设计组件库';

  @override
  String gallery_themeTitle(Object theme) {
    return '$theme主题';
  }

  @override
  String get gallery_colors => '颜色';

  @override
  String get gallery_groupThemeData => 'AppThemeData（随主题）';

  @override
  String get gallery_groupAppColors => 'AppColors（常量调色板）';

  @override
  String get gallery_groupSyntaxColors => 'AppSyntaxColors（当前主题）';

  @override
  String get gallery_typography => '字体排版';

  @override
  String get gallery_pangram => 'The quick brown fox 敏捷的狐狸';

  @override
  String get gallery_metrics => '度量';

  @override
  String get gallery_spacing => '间距';

  @override
  String get gallery_radius => '圆角';

  @override
  String get gallery_height => '高度';

  @override
  String get gallery_shadows => '阴影';

  @override
  String get gallery_shadowNone => 'none（仅边框）';

  @override
  String get gallery_components => '组件';

  @override
  String get gallery_btnPrimary => '主要';

  @override
  String get gallery_btnSecondary => '次要';

  @override
  String get gallery_btnGhost => '幽灵';

  @override
  String get gallery_btnDanger => '危险';

  @override
  String get gallery_btnWithIcon => '带图标';

  @override
  String get gallery_btnSmall => '小尺寸';

  @override
  String get gallery_btnDisabled => '禁用';

  @override
  String get gallery_tipDefault => '默认';

  @override
  String get gallery_tipBordered => '描边';

  @override
  String get gallery_textFieldStandard => '标准（高 32）';

  @override
  String get gallery_textFieldCompact => '紧凑（compact，高 28）';

  @override
  String get gallery_hintSearch => '搜索…';

  @override
  String get gallery_textFieldMultiline => '多行（maxLines: 3）';

  @override
  String get gallery_hintBody => '请求体…';

  @override
  String get gallery_switchOn => '开关：开';

  @override
  String get gallery_switchOff => '开关：关';

  @override
  String get gallery_checked => '已勾选';

  @override
  String get gallery_unchecked => '未勾选';

  @override
  String get gallery_cardStandard => 'standard：surface 底 + border 边';

  @override
  String get gallery_cardElevated => 'elevated：background 底 + shadowMd';

  @override
  String get gallery_selectEnvHint => '选择环境';

  @override
  String get gallery_emptyDemoSubtitle => '创建请求，开始使用';

  @override
  String get ai_callFailedGeneric => 'AI 调用失败';

  @override
  String http_requestTimeout(Object message) {
    return '请求超时：$message';
  }

  @override
  String http_serverError(Object code, Object message) {
    return '服务器错误：$code $message';
  }

  @override
  String get http_requestCancelled => '请求已取消';

  @override
  String http_connectionError(Object message) {
    return '连接错误：$message';
  }

  @override
  String http_networkError(Object message) {
    return '网络错误：$message';
  }

  @override
  String http_unexpectedError(Object message) {
    return '意外错误：$message';
  }

  @override
  String get http_certErrorTitle => 'SSL 证书错误';

  @override
  String get http_certSelfSigned => '服务器正在使用自签名证书。';

  @override
  String get http_certExpired => '服务器的 SSL 证书已过期。';

  @override
  String get http_certHostnameMismatch => '服务器的 SSL 证书与主机名不匹配。';

  @override
  String get http_certUntrusted => '服务器的 SSL 证书不受信任。';

  @override
  String get http_certVerifyFailed => '无法验证服务器的 SSL 证书。';

  @override
  String http_certTechnicalDetails(Object message) {
    return '技术细节：$message';
  }

  @override
  String get http_certTipDisable =>
      '💡 提示：可以在 设置 > SSL/TLS 中关闭「启用 SSL 证书验证」，以便测试时绕过此错误。';

  @override
  String get http_certAlreadyDisabled => '💡 SSL 验证已关闭，但连接仍然失败。';

  @override
  String get http_cancelledByUser => '已被用户取消';

  @override
  String prereq_referencedMissing(Object id) {
    return '引用的请求不存在（$id），可能已被删除';
  }

  @override
  String assertion_operatorNotSupported(Object operator, Object target) {
    return '目标 $target 不支持操作符 $operator';
  }

  @override
  String get assertion_noResponse => '无响应';

  @override
  String get assertion_expectedNotANumber => '期望值不是数字';

  @override
  String assertion_expectedComparison(Object expected, Object operator) {
    return '期望 $operator $expected';
  }

  @override
  String get assertion_headerNotFound => '未找到响应头';

  @override
  String get assertion_headerExists => '响应头存在';

  @override
  String assertion_expectedEquals(Object expected) {
    return '期望为 \"$expected\"';
  }

  @override
  String assertion_expectedNotEquals(Object expected) {
    return '期望不为 \"$expected\"';
  }

  @override
  String assertion_expectedContain(Object expected) {
    return '期望包含 \"$expected\"';
  }

  @override
  String assertion_expectedNotContain(Object expected) {
    return '期望不包含 \"$expected\"';
  }

  @override
  String get assertion_invalidRegex => '无效的正则表达式';

  @override
  String assertion_expectedMatch(Object expected) {
    return '期望匹配 /$expected/';
  }

  @override
  String assertion_expectedBodyContain(Object expected) {
    return '期望响应体包含 \"$expected\"';
  }

  @override
  String assertion_expectedBodyNotContain(Object expected) {
    return '期望响应体不包含 \"$expected\"';
  }

  @override
  String assertion_expectedBodyEqual(Object expected) {
    return '期望响应体等于 \"$expected\"';
  }

  @override
  String assertion_expectedBodyNotEqual(Object expected) {
    return '期望响应体不等于 \"$expected\"';
  }

  @override
  String assertion_expectedBodyMatch(Object expected) {
    return '期望响应体匹配 /$expected/';
  }

  @override
  String get assertion_bodyNotJson => '响应体不是有效的 JSON';

  @override
  String get assertion_invalidJsonPath => '无效的 JSONPath 表达式';

  @override
  String get assertion_pathNotFound => '路径未找到';

  @override
  String get assertion_pathExists => '路径存在';

  @override
  String get assertion_valueNotANumber => '值不是数字';

  @override
  String get assertion_noTimingInfo => '无计时信息';

  @override
  String get var_dynamicDescTimestamp => '当前 Unix 时间戳（秒）';

  @override
  String get var_dynamicDescTimestampMs => '当前 Unix 时间戳（毫秒）';

  @override
  String get var_dynamicDescIsoTimestamp => '当前 UTC ISO8601 时间';

  @override
  String get var_dynamicDescRandomUuid => '随机 UUID v4';

  @override
  String get var_dynamicDescRandomInt => '0–1000000 随机整数';
}
