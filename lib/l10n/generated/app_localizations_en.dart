// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hopp';

  @override
  String get appDescription => 'A lightweight, cross-platform API testing tool';

  @override
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_create => 'Create';

  @override
  String get common_close => 'Close';

  @override
  String get common_send => 'Send';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get sidebar_collections => 'Collections';

  @override
  String get sidebar_newCollection => 'New Collection';

  @override
  String get sidebar_newFolder => 'New Folder';

  @override
  String get sidebar_newRequest => 'New Request';

  @override
  String get sidebar_import => 'Import';

  @override
  String get sidebar_export => 'Export';

  @override
  String get request_params => 'Params';

  @override
  String get request_headers => 'Headers';

  @override
  String get request_body => 'Body';

  @override
  String get request_auth => 'Auth';

  @override
  String get request_urlPlaceholder => 'Enter URL';

  @override
  String get request_namePlaceholder => 'Request Name';

  @override
  String get request_noParams => 'No parameters';

  @override
  String get request_noHeaders => 'No headers';

  @override
  String get request_noBody => 'No body';

  @override
  String get response_body => 'Body';

  @override
  String get response_headers => 'Headers';

  @override
  String get response_cookies => 'Cookies';

  @override
  String get response_status => 'Status';

  @override
  String get response_time => 'Time';

  @override
  String get response_size => 'Size';

  @override
  String get response_copy => 'Copy';

  @override
  String get response_save => 'Save';

  @override
  String get response_noResponse => 'Send a request to see the response';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_themeHint => 'Follow system or switch manually';

  @override
  String get settings_themeLight => 'Light';

  @override
  String get settings_themeDark => 'Dark';

  @override
  String get settings_themeSystem => 'System';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_languageHint =>
      'UI display language, applies immediately';

  @override
  String get settings_uiScale => 'UI Scale';

  @override
  String get settings_uiScaleHint => 'Global text scaling for HiDPI screens';

  @override
  String get common_system => 'System';

  @override
  String get settings_english => 'English';

  @override
  String get settings_chinese => 'Chinese';

  @override
  String get settings_editor => 'Editor';

  @override
  String get settings_fontSize => 'Font Size';

  @override
  String get settings_fontFamily => 'Font Family';

  @override
  String get settings_network => 'Network';

  @override
  String get settings_timeout => 'Timeout (ms)';

  @override
  String get settings_followRedirects => 'Follow Redirects';

  @override
  String get settings_validateCertificates => 'Validate Certificates';

  @override
  String get status_ready => 'Ready';

  @override
  String get status_sending => 'Sending...';

  @override
  String get status_error => 'Error';

  @override
  String sidebar_error(Object err) {
    return 'Error: $err';
  }

  @override
  String get sidebar_themeSystem => 'System theme';

  @override
  String get sidebar_themeLight => 'Light theme';

  @override
  String get sidebar_themeDark => 'Dark theme';

  @override
  String get sidebar_aiSettings => 'AI Settings';

  @override
  String get sidebar_searchHint => 'Filter...';

  @override
  String get sidebar_emptyTitle => 'No collections yet';

  @override
  String get sidebar_emptySubtitle => 'Collections group your API requests';

  @override
  String get sidebar_createCollection => 'Create Collection';

  @override
  String get sidebar_rename => 'Rename';

  @override
  String get sidebar_deleteRequestTitle => 'Delete Request';

  @override
  String sidebar_deleteRequestBody(Object name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get sidebar_addRequest => 'Add Request';

  @override
  String get sidebar_addFolder => 'Add Folder';

  @override
  String get sidebar_folderNameHint => 'Enter folder name';

  @override
  String get sidebar_collectionNameHint => 'Enter collection name';

  @override
  String get sidebar_deleteCollectionTitle => 'Delete Collection';

  @override
  String sidebar_deleteCollectionBody(Object name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get sidebar_importMenu => 'Import…';

  @override
  String get sidebar_refresh => 'Refresh';

  @override
  String get sidebar_about => 'About';

  @override
  String get sidebar_aboutTagline => 'Hop to your APIs';

  @override
  String get sidebar_aboutVersion => 'Version';

  @override
  String get sidebar_aboutPlatform => 'Platform';

  @override
  String get sidebar_aboutFooter => 'Powered by AI · Built with Flutter';

  @override
  String get sidebar_aboutCopyright => '© 2026 Hopp. All rights reserved.';

  @override
  String get sidebar_aboutMoreInfo => 'More Info';

  @override
  String get viewer_copied => 'Copied to clipboard';

  @override
  String get viewer_beautified => 'Code beautified';

  @override
  String get viewer_beautifyFailed => 'Failed to beautify code';

  @override
  String viewer_sizeLines(Object lines, Object size) {
    return '$size • $lines lines';
  }

  @override
  String get viewer_hideTimestamps => 'Hide timestamp annotations';

  @override
  String get viewer_showTimestamps => 'Show timestamp annotations';

  @override
  String get viewer_beautify => 'Beautify';

  @override
  String get viewer_modePerformance => 'Performance';

  @override
  String get viewer_modeFull => 'Full';

  @override
  String viewer_showingLines(Object displayed, Object total) {
    return 'Showing $displayed of $total lines';
  }

  @override
  String viewer_loadMore(Object remaining) {
    return 'Load $remaining more';
  }

  @override
  String get viewer_loadAll => 'Load all';

  @override
  String get viewer_largeResponseTitle => 'Large Response';

  @override
  String viewer_largeResponseBody(Object size) {
    return 'This response is $size which may cause performance issues. Would you like to view it in performance mode?';
  }

  @override
  String get viewer_viewFull => 'View Full';

  @override
  String get viewer_performanceMode => 'Performance Mode';

  @override
  String get editor_enterText => 'Enter text...';

  @override
  String get ai_configNotLoaded =>
      'AI configuration not loaded. Please try again later';

  @override
  String get ai_modelNotConfigured =>
      'Configure a local model (model name) in Settings first';

  @override
  String get ai_noResponseSample => 'Send a request or run it in Tests first';

  @override
  String ai_httpError(Object message) {
    return 'Model service error: $message';
  }

  @override
  String ai_callFailed(Object error) {
    return 'AI call failed: $error';
  }

  @override
  String get ai_connectionFailed =>
      'Local model service not detected. Make sure Ollama / LM Studio is running';

  @override
  String ai_connectionFailedDetail(Object detail) {
    return 'Local model service not detected. Make sure Ollama / LM Studio is running ($detail)';
  }

  @override
  String get ai_timeout =>
      'Local model timed out. It may be loading for the first time or the machine is busy. Please retry';

  @override
  String ai_timeoutDetail(Object detail) {
    return 'Local model timed out. It may be loading for the first time or the machine is busy. Please retry ($detail)';
  }

  @override
  String get ai_responseError =>
      'The model service returned an unexpected response. Please try again later';

  @override
  String ai_responseErrorDetail(Object detail) {
    return 'The model service returned an unexpected response: $detail';
  }

  @override
  String get ai_requestFailed => 'Request failed';

  @override
  String get ai_responseNotJsonObject => 'Response body is not a JSON object';

  @override
  String get ai_choicesEmpty => 'choices is empty';

  @override
  String get ai_choiceMessageMalformed =>
      'Unexpected choices[0].message structure';

  @override
  String get ai_choiceContentEmpty => 'choices[0].message.content is empty';

  @override
  String get ai_parseError =>
      'AI returned an unexpected format. Please try again';

  @override
  String request_preRequestChainFailed(Object error) {
    return 'Pre-request chain failed: $error';
  }

  @override
  String get import_failed => 'Import failed';

  @override
  String import_failedWithError(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get import_resolveConflictFailed => 'Failed to resolve conflict';

  @override
  String import_resolveConflictFailedWithError(Object error) {
    return 'Failed to resolve conflict: $error';
  }

  @override
  String get import_fileNotFound => 'File does not exist';

  @override
  String get import_unknownFormat =>
      'Unrecognized file format. Make sure it is a valid Postman Collection or Environment';

  @override
  String get import_emptyCollection =>
      'The imported collection contains no requests';

  @override
  String import_invalidJson(Object error) {
    return 'Could not parse the JSON file: $error';
  }

  @override
  String import_invalidEnvironmentJson(Object error) {
    return 'Could not parse the Environment file: $error';
  }

  @override
  String get import_unsupportedVersion =>
      'Unsupported Postman Collection version: v1.0. Please upgrade to v2.0 or v2.1 format';

  @override
  String import_environmentSuccess(Object count, Object name) {
    return 'Successfully imported environment \"$name\" ($count variables)';
  }

  @override
  String get import_existingCollectionNotFound =>
      'Could not find the existing collection';

  @override
  String get import_existingCollectionMissing =>
      'The existing collection no longer exists';

  @override
  String export_failedWithError(Object error) {
    return 'Export failed: $error';
  }

  @override
  String export_collectionNotFound(Object id) {
    return 'Collection not found: $id';
  }

  @override
  String get openapi_unknownFormat =>
      'Not recognized as an OpenAPI/Swagger document';

  @override
  String get openapi_missingPaths =>
      'Not recognized as an OpenAPI/Swagger document: missing paths';

  @override
  String get openapi_fetchEmpty => 'Fetch failed: response body is empty';

  @override
  String openapi_fetchFailed(Object error) {
    return 'Fetch failed: $error';
  }

  @override
  String get openapi_noOperations =>
      'The document contains no importable operations';

  @override
  String get openapi_conflictResolveFailed => 'Failed to resolve conflict';

  @override
  String get openapi_noSource =>
      'No import source provided (one of filePath / url / content)';

  @override
  String openapi_parseFailed(Object error) {
    return 'Parse failed: $error';
  }

  @override
  String get openapi_placeholderFormData =>
      'Form fields generated from schema — review and fill in';

  @override
  String get openapi_placeholderBody =>
      'Body generated from schema skeleton — review and fill in';

  @override
  String get openapi_authBearer => 'Bearer Token (fill in token)';

  @override
  String get openapi_authBasic => 'Basic Auth (fill in username/password)';

  @override
  String openapi_authApiKey(Object name, Object where) {
    return 'API Key ($where: $name — fill in the key)';
  }

  @override
  String get curl_emptyInput => 'Please enter a cURL command';

  @override
  String get curl_invalidCommand =>
      'Invalid cURL command. Must start with \"curl\"';

  @override
  String get curl_unknownError => 'Unknown error';

  @override
  String curl_parseFailed(Object error) {
    return 'Failed to parse cURL command: $error';
  }

  @override
  String curl_unsupportedOption(Object option) {
    return 'Unsupported option: -$option';
  }

  @override
  String get collection_saveNoCollection =>
      'Failed to create or find a collection to save the request.';

  @override
  String get collection_notLoaded => 'Collections not loaded yet';

  @override
  String collectionSettings_title(Object name) {
    return '$name · Settings';
  }

  @override
  String get collectionSettings_sectionHeader => 'COLLECTION';

  @override
  String get collectionSettings_navGeneral => 'General';

  @override
  String get collectionSettings_navPreRequest => 'Pre-request';

  @override
  String get collectionSettings_nameLabel => 'Name';

  @override
  String get collectionSettings_descLabel => 'Description';

  @override
  String get collectionSettings_descHint => 'Optional description';

  @override
  String collectionSettings_inheritFrom(Object name) {
    return 'Inherited from parent collection \"$name\". Change it in that collection\'s settings.';
  }

  @override
  String collectionSettings_inheritNoAuth(Object name) {
    return 'Inherited from parent collection \"$name\": No Auth.';
  }

  @override
  String get collectionSettings_rootInherit =>
      'Inherit on a root collection is equivalent to No Auth; no credentials are sent.';

  @override
  String get import_done => 'Done';

  @override
  String get import_retry => 'Retry';

  @override
  String get import_back => 'Back';

  @override
  String get import_importing => 'Importing...';

  @override
  String get import_failedTitle => 'Import Failed';

  @override
  String get import_successTitle => 'Import Successful';

  @override
  String import_successRenamed(Object name) {
    return 'Collection renamed to: $name';
  }

  @override
  String get import_successMerged =>
      'Collection merged with existing collection';

  @override
  String import_successCount(Object count) {
    return 'Successfully imported $count requests';
  }

  @override
  String get import_dropZoneHint =>
      'Click to select file or drag and drop here';

  @override
  String get import_dropZoneSupport =>
      'Supports Postman Collection v2.0/v2.1 and Environment';

  @override
  String get import_selectFile => 'Select File';

  @override
  String get import_parse => 'Parse';

  @override
  String import_importRequest(Object count) {
    return 'Import $count request';
  }

  @override
  String import_importRequests(Object count) {
    return 'Import $count requests';
  }

  @override
  String get import_openCollection => 'Open collection';

  @override
  String import_previewStats(Object selected, Object subCount, Object total) {
    return 'Selected $selected / $total · 1 collection + $subCount sub-collections';
  }

  @override
  String get import_unknownError => 'Unknown error';

  @override
  String get import_selectCollection => 'Select Collection';

  @override
  String conflict_title(Object name) {
    return '\"$name\" Already Exists';
  }

  @override
  String get conflict_prompt => 'Please choose how to handle this:';

  @override
  String get conflict_rename => 'Rename Import';

  @override
  String conflict_renameSubtitle(Object name) {
    return 'Rename imported collection to \"$name (1)\"';
  }

  @override
  String get conflict_overwrite => 'Overwrite Existing';

  @override
  String get conflict_overwriteSubtitle =>
      'Replace existing collection with imported content';

  @override
  String get conflict_merge => 'Merge Collections';

  @override
  String get conflict_mergeSubtitle =>
      'Keep existing requests and add new ones';

  @override
  String get conflict_skip => 'Skip';

  @override
  String get conflict_skipSubtitle => 'Cancel import for this collection';

  @override
  String get conflict_confirm => 'Confirm';

  @override
  String get conflict_dialogTitle => 'Duplicate Collection Name';

  @override
  String conflict_dialogMessage(Object name) {
    return '\"$name\" already exists. Please choose how to handle this:';
  }

  @override
  String get conflict_skipThis => 'Skip This Collection';

  @override
  String get conflict_applyToAll => 'Apply to all conflicts';

  @override
  String get export_loadFailed => 'Unable to load collection list';

  @override
  String get export_exporting => 'Exporting...';

  @override
  String get export_exportingCollection => 'Exporting collection...';

  @override
  String get export_successTitle => 'Export Successful';

  @override
  String get export_savedTo => 'File saved to:';

  @override
  String get export_failedTitle => 'Export Failed';

  @override
  String get export_dialogTitle => 'Export Collection';

  @override
  String get export_formatHeader => 'FORMAT';

  @override
  String get export_formatPostman => 'Postman Collection';

  @override
  String get export_formatPostmanDesc1 =>
      'Interchange with Postman / other tools. Assertions and pre-request chains are ';

  @override
  String get export_formatPostmanDescNot => 'not';

  @override
  String get export_formatPostmanDesc2 =>
      ' included (format cannot express them).';

  @override
  String get export_formatHoppDesc1 =>
      'Full fidelity: assertions, pre-request chains, auth and variable pipelines. Run in CI with ';

  @override
  String get export_formatHoppDesc2 => '.';

  @override
  String get export_secretNotice1 =>
      'Secret variable values are exported empty. Inject them in CI with ';

  @override
  String get export_secretNotice2 => ' or process environment variables.';

  @override
  String get export_formatVersion => 'Format Version';

  @override
  String get export_prettify => 'Prettify JSON Output';

  @override
  String get export_prettifyHint => 'Format with indentation for readability';

  @override
  String get export_saveHoppTitle => 'Save Hopp CLI Collection';

  @override
  String get export_savePostmanTitle => 'Save Postman Collection';

  @override
  String get curl_importAndSend => 'Import & Send';

  @override
  String get curl_commandLabel => 'cURL Command';

  @override
  String get curl_paste => 'Paste';

  @override
  String get curl_emptyPreview => 'Parsed request will appear here';

  @override
  String get curl_parsing => 'Parsing...';

  @override
  String get curl_parseError => 'Parse Error';

  @override
  String get curl_parsedSuccess => 'Parsed Successfully';

  @override
  String curl_warningCountOne(Object count) {
    return '$count warning';
  }

  @override
  String curl_warningCountMany(Object count) {
    return '$count warnings';
  }

  @override
  String get curl_labelMethod => 'Method';

  @override
  String get curl_labelUrl => 'URL';

  @override
  String curl_headersEnabled(Object count) {
    return '$count enabled';
  }

  @override
  String get curl_labelBodyType => 'Body Type';

  @override
  String get curl_labelBodySize => 'Body Size';

  @override
  String curl_bodyBytes(Object count) {
    return '$count bytes';
  }

  @override
  String get curl_sslVerifyOff => 'SSL verify: OFF';

  @override
  String get curl_followRedirectsOn => 'Follow redirects: ON';

  @override
  String get curl_warningsLabel => 'Warnings:';

  @override
  String get curl_requestNameHint => 'Enter request name...';

  @override
  String get curl_noCollections =>
      'No collections available. Please create a collection first.';

  @override
  String get curl_saveToCollection => 'Save to Collection';

  @override
  String get curl_loadFailed => 'Failed to load collections';

  @override
  String get openapi_parsing => 'Parsing spec…';

  @override
  String get openapi_importing => 'Importing…';

  @override
  String get openapi_dropZoneHint => 'Click to select a spec file';

  @override
  String get openapi_dropZoneSupport =>
      'Supports .json / .yaml / .yml · OpenAPI 3.x · Swagger 2.0';

  @override
  String get openapi_orFromUrl => 'Or import from URL';

  @override
  String get openapi_specUrlLabel => 'Spec URL';

  @override
  String get openapi_specUrlHint =>
      'Machine-readable address (openapi.json / swagger.yaml), parsed locally — data never leaves your machine.';

  @override
  String get openapi_headerLabel => 'Header';

  @override
  String get openapi_headerHint =>
      'Optional. One custom header used only for this fetch (private specs). Not saved.';

  @override
  String openapi_specSummary(Object opCount, Object tagCount, Object version) {
    return ' · OpenAPI $version · $tagCount tags · $opCount operations';
  }

  @override
  String get openapi_serverLabel => ' · Server ';

  @override
  String get openapi_searchHint => 'Search path or name…';

  @override
  String get openapi_selectAll => 'Select all';

  @override
  String get openapi_selectNone => 'Select none';

  @override
  String get openapi_noMatch => 'No operations match your search';

  @override
  String get openapi_noTag => 'No tag';

  @override
  String get openapi_statRequests => 'Requests imported';

  @override
  String get openapi_statPlaceholders => 'Placeholders';

  @override
  String openapi_importedAs(Object name) {
    return 'Imported as \"$name\"';
  }

  @override
  String openapi_mergedInto(Object name) {
    return 'Merged into existing collection \"$name\"';
  }

  @override
  String get openapi_placeholdersHeader =>
      'PLACEHOLDERS (VALUES FROM SCHEMA SKELETON, NOT SPEC EXAMPLES)';

  @override
  String openapi_oauthNotice(Object schemes) {
    return 'OAuth2 / OpenID Connect scheme(s) $schemes were not configured automatically. Go to Collection settings → Auth to complete the authorization flow.';
  }

  @override
  String openapi_authConfigured(Object description) {
    return 'Configured collection-level Auth: $description.';
  }

  @override
  String get curl_inputHint => 'Paste cURL command here...';

  @override
  String get curl_inputHintExample => 'Example:';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_show => 'Show';

  @override
  String get common_hide => 'Hide';

  @override
  String get request_selectRequestTitle => 'Select a request';

  @override
  String get request_selectRequestSubtitle =>
      'Select a request from the sidebar or create a new one';

  @override
  String request_unresolvedVariables(Object variables) {
    return 'Unresolved variables: $variables';
  }

  @override
  String get request_tabPreRequest => 'Pre-request';

  @override
  String get request_tabAssertions => 'Assertions';

  @override
  String get request_keyColumn => 'Key';

  @override
  String get request_valueColumn => 'Value';

  @override
  String get request_descriptionColumn => 'Description';

  @override
  String get request_addNewRow => 'Add new';

  @override
  String get request_noBodyContent => 'No body content';

  @override
  String get request_selectBodyTypeHint => 'Select a body type to add content';

  @override
  String get request_formDataComingSoon => 'form-data editor (coming soon)';

  @override
  String get request_urlEncodedComingSoon =>
      'x-www-form-urlencoded editor (coming soon)';

  @override
  String get request_bodySectionTitle => 'BODY';

  @override
  String get request_selectFile => 'Select file';

  @override
  String get request_chooseFile => 'Choose File';

  @override
  String get request_graphqlComingSoon => 'GraphQL editor (coming soon)';

  @override
  String request_inheritSummaryNoAuth(Object name) {
    return 'Inherited from collection \"$name\": No Auth — no credentials will be sent.';
  }

  @override
  String request_inheritSummary(Object authType, Object name) {
    return 'Inherited from collection \"$name\": $authType. Edit it in collection settings.';
  }

  @override
  String get request_sslVerification => 'Enable SSL certificate verification';

  @override
  String get request_sslVerificationHint =>
      'Verify the server\'s SSL certificate chain';

  @override
  String get request_sslDisableNote =>
      'Disable this option to allow self-signed certificates or bypass certificate errors for testing purposes.';

  @override
  String get request_redirectsSection => 'Redirects';

  @override
  String get request_followRedirects => 'Follow redirects';

  @override
  String get request_followRedirectsHint =>
      'Automatically follow HTTP 3xx redirects';

  @override
  String get request_maxRedirects => 'Maximum redirects';

  @override
  String get request_maxRedirectsHint =>
      'Limit the number of redirects to follow (0 = unlimited)';

  @override
  String get request_comingSoonSection => 'Coming Soon';

  @override
  String get request_timeoutTitle => 'Request timeout';

  @override
  String get request_timeoutHint => 'Set the request timeout duration';

  @override
  String get request_savedToCollection => 'Request saved to collection';

  @override
  String get request_saveFailed => 'Failed to save request';

  @override
  String get request_saveFailedCollection =>
      'Unable to save: Collection error. Please try again.';

  @override
  String get request_headerDescAccept =>
      'Media types that are acceptable for the response';

  @override
  String get request_headerDescAcceptCharset =>
      'Character sets that are acceptable';

  @override
  String get request_headerDescAcceptEncoding =>
      'List of acceptable encodings (gzip, deflate, br)';

  @override
  String get request_headerDescAcceptLanguage =>
      'List of acceptable human languages';

  @override
  String get request_headerDescAuthorization =>
      'Authentication credentials (Bearer token, Basic auth)';

  @override
  String get request_headerDescCacheControl =>
      'Directives for caching mechanisms';

  @override
  String get request_headerDescConnection =>
      'Control options for the current connection (keep-alive)';

  @override
  String get request_headerDescContentLength =>
      'The length of the request body in octets';

  @override
  String get request_headerDescContentType =>
      'The MIME type of the body (application/json)';

  @override
  String get request_headerDescCookie =>
      'An HTTP cookie previously sent by the server';

  @override
  String get request_headerDescHost =>
      'The domain name of the server (and optional port)';

  @override
  String get request_headerDescOrigin =>
      'Indicates where a fetch originates from';

  @override
  String get request_headerDescReferer =>
      'The address of the previous web page';

  @override
  String get request_headerDescUserAgent =>
      'The user agent string of the client';

  @override
  String get request_headerDescXRequestedWith =>
      'Used to identify AJAX requests';

  @override
  String get assertion_targetStatus => 'Status code';

  @override
  String get assertion_targetHeader => 'Header';

  @override
  String get assertion_targetBody => 'Body text';

  @override
  String get assertion_targetJsonPath => 'JSONPath';

  @override
  String get assertion_targetResponseTime => 'Response time';

  @override
  String get assertion_title => 'Response assertions';

  @override
  String get assertion_noteEvaluated => 'Evaluated after every send. ';

  @override
  String get assertion_noteExpectedPrefix => 'Expected values support ';

  @override
  String get assertion_noteExpectedSuffix => '.';

  @override
  String get assertion_add => 'Add assertion';

  @override
  String get assertion_colTarget => 'TARGET';

  @override
  String get assertion_colNamePath => 'NAME / PATH';

  @override
  String get assertion_colOperator => 'OPERATOR';

  @override
  String get assertion_colExpected => 'EXPECTED';

  @override
  String get assertion_headerNameHint => 'Header name';

  @override
  String get assertion_expectedHint => 'Expected value';

  @override
  String get assertion_hintPrefix => 'Operators are filtered by target — e.g. ';

  @override
  String get assertion_hintNoExpected => ' needs no expected value; ';

  @override
  String get assertion_hintComparison =>
      ' apply to Status code / Response time. Response time is in milliseconds.';

  @override
  String get assertion_emptyTitle => 'No assertions yet';

  @override
  String get assertion_emptySubtitle =>
      'Add one to validate the response after every send';

  @override
  String get auth_typeSectionTitle => 'AUTH TYPE';

  @override
  String get auth_typeInherit => 'Inherit';

  @override
  String get auth_typeNone => 'No Auth';

  @override
  String get auth_typeBearer => 'Bearer Token';

  @override
  String get auth_typeBasic => 'Basic Auth';

  @override
  String get auth_typeApiKey => 'API Key';

  @override
  String get auth_inheritDesc =>
      'Follows the auth configuration of the parent collection.';

  @override
  String get auth_inheritNotFound =>
      'No auth configuration found in the inheritance chain; no credentials will be sent.';

  @override
  String get auth_noneDesc =>
      'No credentials are sent, and inheritance from the collection is blocked.';

  @override
  String get auth_bearerDesc =>
      'Automatically attaches Authorization: Bearer <token> when sending; any same-name header is overridden.';

  @override
  String get auth_tokenLabel => 'Token';

  @override
  String get auth_basicDesc =>
      'Automatically attaches Authorization: Basic base64(user:pass) when sending.';

  @override
  String get auth_username => 'Username';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_apiKeyDesc =>
      'Injects a custom key into a header or query params.';

  @override
  String get auth_keyLabel => 'Key';

  @override
  String get auth_addTo => 'Add to';

  @override
  String get auth_addToHeader => 'Header';

  @override
  String get auth_addToQuery => 'Query Params';

  @override
  String auth_variableHint(Object example, Object variable) {
    return 'All fields support $variable and transform pipelines (e.g. $example).';
  }

  @override
  String get prerequest_title => 'Pre-request Chain';

  @override
  String get prerequest_subtitle =>
      'Executed in order before this request is sent; variables produced by steps go to the local scope, valid only for this session and do not pollute environments';

  @override
  String get prerequest_addStep => 'Add Step';

  @override
  String get prerequest_testRun => 'Test Run';

  @override
  String get prerequest_emptyTitle => 'No pre-request steps yet';

  @override
  String prerequest_emptyHint(Object token) {
    return 'Typical scenario: run a login request first, then extract $token from the response';
  }

  @override
  String get prerequest_selectRequest => 'Select request…';

  @override
  String get prerequest_requestDeleted =>
      'The referenced request has been deleted';

  @override
  String get prerequest_deleteStep => 'Delete step';

  @override
  String get prerequest_extractHeader =>
      'EXTRACT · Extract variables from response';

  @override
  String get prerequest_sourceJsonPath => 'Body · JSONPath';

  @override
  String get prerequest_sourceHeader => 'Header';

  @override
  String get prerequest_sourceRegex => 'Body · Regex';

  @override
  String get prerequest_deleteRule => 'Delete rule';

  @override
  String get prerequest_addRule => 'Add extraction rule';

  @override
  String get prerequest_policyTitle => 'Expiration Policy';

  @override
  String get prerequest_retry401Hint =>
      'Automatically re-run the chain on 401 (off = resend manually after sending)';

  @override
  String get prerequest_scopeTooltip =>
      'Chain variables go to the local scope (session-level) and do not pollute environments';

  @override
  String get prerequest_scopeLocal => 'Variable scope: Local';

  @override
  String get prerequest_resultTitle => 'Test Run Results';

  @override
  String get prerequest_allSucceeded => 'All steps succeeded';

  @override
  String get prerequest_someStepsFailed => 'Some steps failed';

  @override
  String get prerequest_noVariables =>
      'No variables produced (check extraction rules)';

  @override
  String prerequest_stepN(Object index) {
    return 'Step $index';
  }

  @override
  String prerequest_missingValue(Object path, Object variable) {
    return '$path → $variable: no value extracted';
  }

  @override
  String get fx_tooltip => 'Variable preview & transform functions';

  @override
  String get fx_resolvedPreview => 'RESOLVED PREVIEW';

  @override
  String get fx_insertDynamicVariable => 'INSERT DYNAMIC VARIABLE';

  @override
  String get fx_insertTransform => 'INSERT TRANSFORM';

  @override
  String fx_emptyHint(Object variable) {
    return 'Type $variable to preview resolved values here';
  }

  @override
  String get fx_undefined => '(undefined)';

  @override
  String get fx_transformFailed => '(transform failed)';

  @override
  String get fx_dateAddFormatError =>
      'Format: [+-]integer + unit (s/m/h/d/w), e.g. -7d';

  @override
  String get fx_dateAddUnitHint =>
      'Units: s seconds / m minutes / h hours / d days / w weeks; base is a 10-digit seconds or 13-digit milliseconds epoch.';

  @override
  String get fx_floorHour => 'hour · start of current hour';

  @override
  String get fx_floorDay => 'day · start of today';

  @override
  String get fx_floorWeek => 'week · start of this Monday';

  @override
  String get fx_floorMonth => 'month · start of the 1st of this month';

  @override
  String get fx_dateFloorHint =>
      'Floored in the local timezone; base is a 10-digit seconds or 13-digit milliseconds epoch, output keeps the same unit.';

  @override
  String get fx_insert => 'Insert';

  @override
  String fx_aesKeyHint(Object sample) {
    return '$sample · 16/24/32 bytes';
  }

  @override
  String fx_aesIvHint(Object sample) {
    return '$sample · cbc requires 16 bytes';
  }

  @override
  String fx_paramVariableHint(Object variable) {
    return 'Parameters support $variable references.';
  }

  @override
  String get response_noResponseYet => 'No response yet';

  @override
  String get response_copyResponse => 'Copy response';

  @override
  String get response_saveResponse => 'Save response';

  @override
  String get response_noResponseTitle => 'No response';

  @override
  String get response_noHeadersTitle => 'No headers';

  @override
  String get response_noHeadersHint => 'Send a request to see response headers';

  @override
  String get response_headerNameColumn => 'Header Name';

  @override
  String get response_cookiesComingSoon => 'Cookie management coming soon';

  @override
  String get response_noRequestTitle => 'No Request';

  @override
  String get response_noRequestHint => 'Create a request to see details';

  @override
  String response_headersCount(Object count) {
    return 'Headers ($count)';
  }

  @override
  String response_bodyWithType(Object type) {
    return 'Body ($type)';
  }

  @override
  String get response_urlScheme => 'Scheme';

  @override
  String get response_urlHost => 'Host';

  @override
  String get response_urlPort => 'Port';

  @override
  String get response_urlPath => 'Path';

  @override
  String response_customCount(Object count) {
    return '$count custom';
  }

  @override
  String get response_autoAddedHeaders => 'Auto-added Headers';

  @override
  String get response_autoBadge => 'auto';

  @override
  String get response_totalRequestTime => 'Total Request Time';

  @override
  String get response_phaseBreakdown => 'Phase Breakdown';

  @override
  String get response_dnsLookup => 'DNS Lookup';

  @override
  String get response_tcpConnect => 'TCP Connect';

  @override
  String get response_tlsHandshake => 'TLS Handshake';

  @override
  String get response_ttfb => 'TTFB (Time to First Byte)';

  @override
  String get response_download => 'Download';

  @override
  String get response_timeline => 'Timeline';

  @override
  String response_assertionsPassed(Object passed, Object total) {
    return '$passed/$total passed';
  }

  @override
  String get response_tabRequest => 'Request';

  @override
  String get response_tabTests => 'Tests';

  @override
  String get response_tabTiming => 'Timing';

  @override
  String get response_tabCertificate => 'Certificate';

  @override
  String get response_noAssertionsConfigured =>
      'No assertions configured — add them in the Assertions tab.';

  @override
  String get response_assertionsNotRun =>
      'Not run yet — send the request to evaluate assertions.';

  @override
  String get response_assertionDisabled => 'disabled';

  @override
  String response_expectedValueAt(Object arg) {
    return 'value at $arg';
  }

  @override
  String response_expectedHeader(Object arg) {
    return 'header \"$arg\"';
  }

  @override
  String get response_expectedPresent => 'present';

  @override
  String get response_expectedLabel => 'EXPECTED';

  @override
  String get response_actualLabel => 'ACTUAL';

  @override
  String get response_resolvedLabel => 'RESOLVED';

  @override
  String get response_certValid => 'Certificate is valid';

  @override
  String get response_certExpired => 'Certificate expired';

  @override
  String response_certDaysRemaining(Object days) {
    return '$days days remaining';
  }

  @override
  String response_certExpiredOn(Object date) {
    return 'Expired on $date';
  }

  @override
  String get response_certDetails => 'Certificate Details';

  @override
  String get response_certSubject => 'Subject';

  @override
  String get response_certIssuer => 'Issuer';

  @override
  String get response_certValidFrom => 'Valid From';

  @override
  String get response_certValidTo => 'Valid To';

  @override
  String get response_certSignatureAlgorithm => 'Signature Algorithm';

  @override
  String get response_certSerialNumber => 'Serial Number';

  @override
  String get response_certSha256 => 'SHA-256 Fingerprint';

  @override
  String get response_certPublicKeyAlgorithm => 'Public Key Algorithm';

  @override
  String get response_certPublicKeyLength => 'Public Key Length';

  @override
  String get response_certSan => 'Subject Alternative Names';

  @override
  String response_certBits(Object bits) {
    return '$bits bits';
  }

  @override
  String get response_certChain => 'Certificate Chain';

  @override
  String response_certIssuedBy(Object issuer) {
    return 'Issued by: $issuer';
  }

  @override
  String get response_copiedToClipboard => 'Copied to clipboard';

  @override
  String get env_selectTooltip => 'Select environment';

  @override
  String get env_none => 'No Environment';

  @override
  String env_unresolvedVariables(Object variables) {
    return 'Unresolved variables: $variables';
  }

  @override
  String get env_manage => 'Manage Environments';

  @override
  String get env_globals => 'Globals';

  @override
  String env_footerHint(Object varRef) {
    return 'Reference variables as $varRef in URL, headers and body · secret values are write-only';
  }

  @override
  String env_variableCount(Object count, Object varRef) {
    return '$count variables · referenced as $varRef';
  }

  @override
  String get env_globalsHint =>
      'Shared across all environments · overridden by environment variables';

  @override
  String get env_sectionEnvironments => 'ENVIRONMENTS';

  @override
  String get env_sectionShared => 'SHARED';

  @override
  String get env_newEnvironment => 'New Environment';

  @override
  String get env_nameHint => 'Name';

  @override
  String get env_deleteTooltip => 'Delete environment';

  @override
  String get env_emptyTitle => 'No variables yet';

  @override
  String env_emptySubtitle(Object varRef) {
    return 'Add one and reference it as $varRef';
  }

  @override
  String get env_addVariable => 'Add Variable';

  @override
  String get env_headerKey => 'KEY';

  @override
  String get env_headerValue => 'VALUE';

  @override
  String get env_headerType => 'TYPE';

  @override
  String get env_keyHint => 'Key';

  @override
  String get env_valueHint => 'Value';

  @override
  String get env_showValue => 'Show value';

  @override
  String get env_hideValue => 'Hide value';

  @override
  String get env_removeVariable => 'Remove variable';

  @override
  String get ai_presetCustom => 'Custom';

  @override
  String get ai_settingsTitle => 'AI Settings';

  @override
  String get ai_notReady => 'Local AI is not enabled or no model is configured';

  @override
  String get ai_openSettings => 'Open Settings';

  @override
  String get ai_enableLocal => 'Enable Local AI';

  @override
  String get ai_providerPreset => 'Provider Preset';

  @override
  String get ai_baseUrl => 'Base URL';

  @override
  String get ai_model => 'Model';

  @override
  String get ai_modelHint => 'Enter manually, e.g. llama3.1:8b';

  @override
  String get ai_apiKey => 'API Key';

  @override
  String get ai_apiKeyHint => 'Leave empty';

  @override
  String get ai_apiKeyNote =>
      'Local models usually work without a key; only needed for Tier 2 cloud providers';

  @override
  String get ai_connIdle => 'Connection not checked yet';

  @override
  String get ai_connChecking => 'Checking connection...';

  @override
  String get ai_connected => 'Connected';

  @override
  String get ai_checkConnection => 'Check Connection';

  @override
  String get ai_explainTitle => 'Explain Response';

  @override
  String get ai_noResponseToExplain => 'No response to explain';

  @override
  String get ai_regenerate => 'Regenerate';

  @override
  String get ai_explaining =>
      'Explaining... (local models may take 10–30 seconds)';

  @override
  String get ai_retry => 'Retry';

  @override
  String get ai_buildTitle => 'Build Request with Natural Language';

  @override
  String get ai_overwriteTitle => 'Overwrite current request?';

  @override
  String get ai_overwriteMessage =>
      'The current request already has content. Applying the draft will overwrite its URL, Params, Headers, and Body.';

  @override
  String get ai_overwrite => 'Overwrite';

  @override
  String get ai_generating =>
      'Generating... (local models may take 10–30 seconds)';

  @override
  String get ai_buildDescHint =>
      'Describe the request you want, e.g. POST create user with a JSON body containing name and email, requires auth';

  @override
  String get ai_buildDraftNote =>
      'The result is a draft you can keep editing after applying; field values come only from your description';

  @override
  String get ai_zeroRows => '0 rows';

  @override
  String get ai_sectionParams => 'PARAMS';

  @override
  String get ai_sectionHeaders => 'HEADERS';

  @override
  String ai_sectionBody(Object type) {
    return 'BODY · $type';
  }

  @override
  String get ai_applyDraft => 'Apply to Current Request';

  @override
  String get ai_generate => 'Generate';

  @override
  String get ai_generateButton => 'AI Generate';

  @override
  String get ai_needResponseSample => 'Run tests or send a request first';

  @override
  String get ai_genAssertionsTitle => 'AI Generate Assertions';

  @override
  String ai_genSelected(Object checked, Object total) {
    return 'Generated from the latest response · $checked/$total selected';
  }

  @override
  String ai_genDiscarded(Object count) {
    return 'Discarded $count invalid suggestions';
  }

  @override
  String ai_addChecked(Object count) {
    return 'Add $count';
  }

  @override
  String get ai_generatingAssertions =>
      'Generating assertions... (local models may take 10–30 seconds)';

  @override
  String get ai_noSuggestions =>
      'No usable assertion suggestions were generated';

  @override
  String get ai_colTarget => 'TARGET';

  @override
  String get ai_colPath => 'PATH';

  @override
  String get ai_colOperator => 'OPERATOR';

  @override
  String get ai_colExpected => 'EXPECTED';

  @override
  String get ai_headerNameHint => 'Header name';

  @override
  String get ai_expectedValueHint => 'Expected value';

  @override
  String get main_emptyTitle => 'No requests yet';

  @override
  String get main_emptySubtitle => 'Get started by creating your first request';

  @override
  String get main_createRequest => 'Create Request';

  @override
  String get main_emptyShortcutHint => 'or press Cmd+N';

  @override
  String get main_selectTab => 'Select a tab to start';

  @override
  String get about_title => 'About';

  @override
  String get about_tagline => 'Hop to your APIs';

  @override
  String get about_version => 'Version';

  @override
  String get about_description => 'Description';

  @override
  String get about_descriptionContent =>
      'A lightweight, cross-platform API testing tool built with Flutter. Hopp makes API testing simple, fast, and enjoyable.';

  @override
  String get about_features => 'Features';

  @override
  String get about_featureLightweight => '🔥 Lightweight & Fast';

  @override
  String get about_featureCrossPlatform =>
      '💻 Cross-Platform (macOS, Windows, Linux)';

  @override
  String get about_featureHttp => '📝 Full HTTP Request Support';

  @override
  String get about_featureCollections => '📦 Collection Management';

  @override
  String get about_featureTabs => '📑 Multiple Tabs';

  @override
  String get about_featureDarkMode => '🌓 Dark Mode Support';

  @override
  String get about_featureLanguages => '🌍 Multi-language Support';

  @override
  String get about_featureLocal => '🔒 Local Data Storage';

  @override
  String get about_techStack => 'Tech Stack';

  @override
  String get about_links => 'Links';

  @override
  String get about_githubRepo => 'GitHub Repository';

  @override
  String get about_reportIssues => 'Report Issues';

  @override
  String get about_reportIssuesSubtitle =>
      'Submit bug reports and feature requests';

  @override
  String get about_contribute => 'Contribute';

  @override
  String get about_contributeSubtitle => 'Help make Hopp better';

  @override
  String get about_builtWith => 'Built with passion by the Hopp team';

  @override
  String get about_copyright => '© 2026 Hopp. All rights reserved.';

  @override
  String get about_poweredBy => 'Powered by AI · Built with Flutter';

  @override
  String get gallery_title => 'Design Gallery';

  @override
  String gallery_themeTitle(Object theme) {
    return '$theme Theme';
  }

  @override
  String get gallery_colors => 'Colors';

  @override
  String get gallery_groupThemeData => 'AppThemeData (theme-dependent)';

  @override
  String get gallery_groupAppColors => 'AppColors (constant palette)';

  @override
  String get gallery_groupSyntaxColors => 'AppSyntaxColors (current theme)';

  @override
  String get gallery_typography => 'Typography';

  @override
  String get gallery_pangram => 'The quick brown fox 敏捷的狐狸';

  @override
  String get gallery_metrics => 'Metrics';

  @override
  String get gallery_spacing => 'Spacing';

  @override
  String get gallery_radius => 'Radius';

  @override
  String get gallery_height => 'Height';

  @override
  String get gallery_shadows => 'Shadows';

  @override
  String get gallery_shadowNone => 'none (border only)';

  @override
  String get gallery_components => 'Components';

  @override
  String get gallery_btnPrimary => 'Primary';

  @override
  String get gallery_btnSecondary => 'Secondary';

  @override
  String get gallery_btnGhost => 'Ghost';

  @override
  String get gallery_btnDanger => 'Danger';

  @override
  String get gallery_btnWithIcon => 'With Icon';

  @override
  String get gallery_btnSmall => 'Small';

  @override
  String get gallery_btnDisabled => 'Disabled';

  @override
  String get gallery_tipDefault => 'Default';

  @override
  String get gallery_tipBordered => 'Bordered';

  @override
  String get gallery_textFieldStandard => 'Standard (height 32)';

  @override
  String get gallery_textFieldCompact => 'Compact (height 28)';

  @override
  String get gallery_hintSearch => 'Search…';

  @override
  String get gallery_textFieldMultiline => 'Multiline (maxLines: 3)';

  @override
  String get gallery_hintBody => 'Body…';

  @override
  String get gallery_switchOn => 'switch on';

  @override
  String get gallery_switchOff => 'switch off';

  @override
  String get gallery_checked => 'checked';

  @override
  String get gallery_unchecked => 'unchecked';

  @override
  String get gallery_cardStandard => 'standard: surface background + border';

  @override
  String get gallery_cardElevated => 'elevated: background + shadowMd';

  @override
  String get gallery_selectEnvHint => 'Select env';

  @override
  String get gallery_emptyDemoSubtitle => 'Create a request to get started';

  @override
  String get ai_callFailedGeneric => 'AI call failed';

  @override
  String http_requestTimeout(Object message) {
    return 'Request timeout: $message';
  }

  @override
  String http_serverError(Object code, Object message) {
    return 'Server error: $code $message';
  }

  @override
  String get http_requestCancelled => 'Request cancelled';

  @override
  String http_connectionError(Object message) {
    return 'Connection error: $message';
  }

  @override
  String http_networkError(Object message) {
    return 'Network error: $message';
  }

  @override
  String http_unexpectedError(Object message) {
    return 'Unexpected error: $message';
  }

  @override
  String get http_certErrorTitle => 'SSL Certificate Error';

  @override
  String get http_certSelfSigned =>
      'The server is using a self-signed certificate.';

  @override
  String get http_certExpired => 'The server\'s SSL certificate has expired.';

  @override
  String get http_certHostnameMismatch =>
      'The server\'s SSL certificate does not match the hostname.';

  @override
  String get http_certUntrusted =>
      'The server\'s SSL certificate is not trusted.';

  @override
  String get http_certVerifyFailed =>
      'Unable to verify the server\'s SSL certificate.';

  @override
  String http_certTechnicalDetails(Object message) {
    return 'Technical details: $message';
  }

  @override
  String get http_certTipDisable =>
      '💡 Tip: You can disable \"Enable SSL certificate verification\" in Settings > SSL/TLS to bypass this error for testing purposes.';

  @override
  String get http_certAlreadyDisabled =>
      '💡 SSL verification is already disabled, but the connection still failed.';

  @override
  String get http_cancelledByUser => 'Cancelled by user';

  @override
  String prereq_referencedMissing(Object id) {
    return 'Referenced request not found ($id); it may have been deleted';
  }

  @override
  String assertion_operatorNotSupported(Object operator, Object target) {
    return 'operator $operator is not supported for target $target';
  }

  @override
  String get assertion_noResponse => 'no response';

  @override
  String get assertion_expectedNotANumber => 'expected not a number';

  @override
  String assertion_expectedComparison(Object expected, Object operator) {
    return 'expected $operator $expected';
  }

  @override
  String get assertion_headerNotFound => 'header not found';

  @override
  String get assertion_headerExists => 'header exists';

  @override
  String assertion_expectedEquals(Object expected) {
    return 'expected \"$expected\"';
  }

  @override
  String assertion_expectedNotEquals(Object expected) {
    return 'expected not \"$expected\"';
  }

  @override
  String assertion_expectedContain(Object expected) {
    return 'expected to contain \"$expected\"';
  }

  @override
  String assertion_expectedNotContain(Object expected) {
    return 'expected not to contain \"$expected\"';
  }

  @override
  String get assertion_invalidRegex => 'invalid regex';

  @override
  String assertion_expectedMatch(Object expected) {
    return 'expected to match /$expected/';
  }

  @override
  String assertion_expectedBodyContain(Object expected) {
    return 'expected body to contain \"$expected\"';
  }

  @override
  String assertion_expectedBodyNotContain(Object expected) {
    return 'expected body not to contain \"$expected\"';
  }

  @override
  String assertion_expectedBodyEqual(Object expected) {
    return 'expected body to equal \"$expected\"';
  }

  @override
  String assertion_expectedBodyNotEqual(Object expected) {
    return 'expected body not to equal \"$expected\"';
  }

  @override
  String assertion_expectedBodyMatch(Object expected) {
    return 'expected body to match /$expected/';
  }

  @override
  String get assertion_bodyNotJson => 'response body is not valid JSON';

  @override
  String get assertion_invalidJsonPath => 'invalid JSONPath expression';

  @override
  String get assertion_pathNotFound => 'path not found';

  @override
  String get assertion_pathExists => 'path exists';

  @override
  String get assertion_valueNotANumber => 'value is not a number';

  @override
  String get assertion_noTimingInfo => 'no timing info';

  @override
  String get var_dynamicDescTimestamp => 'Current Unix timestamp (seconds)';

  @override
  String get var_dynamicDescTimestampMs =>
      'Current Unix timestamp (milliseconds)';

  @override
  String get var_dynamicDescIsoTimestamp => 'Current UTC ISO8601 time';

  @override
  String get var_dynamicDescRandomUuid => 'Random UUID v4';

  @override
  String get var_dynamicDescRandomInt => 'Random integer between 0 and 1000000';
}
