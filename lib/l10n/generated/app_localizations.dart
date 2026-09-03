import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hopp'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A lightweight, cross-platform API testing tool'**
  String get appDescription;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get common_send;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @sidebar_collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get sidebar_collections;

  /// No description provided for @sidebar_newCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get sidebar_newCollection;

  /// No description provided for @sidebar_newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get sidebar_newFolder;

  /// No description provided for @sidebar_newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get sidebar_newRequest;

  /// No description provided for @sidebar_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get sidebar_import;

  /// No description provided for @sidebar_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get sidebar_export;

  /// No description provided for @request_params.
  ///
  /// In en, this message translates to:
  /// **'Params'**
  String get request_params;

  /// No description provided for @request_headers.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get request_headers;

  /// No description provided for @request_body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get request_body;

  /// No description provided for @request_auth.
  ///
  /// In en, this message translates to:
  /// **'Auth'**
  String get request_auth;

  /// No description provided for @request_urlPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter URL'**
  String get request_urlPlaceholder;

  /// No description provided for @request_namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Request Name'**
  String get request_namePlaceholder;

  /// No description provided for @request_noParams.
  ///
  /// In en, this message translates to:
  /// **'No parameters'**
  String get request_noParams;

  /// No description provided for @request_noHeaders.
  ///
  /// In en, this message translates to:
  /// **'No headers'**
  String get request_noHeaders;

  /// No description provided for @request_noBody.
  ///
  /// In en, this message translates to:
  /// **'No body'**
  String get request_noBody;

  /// No description provided for @response_body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get response_body;

  /// No description provided for @response_headers.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get response_headers;

  /// No description provided for @response_cookies.
  ///
  /// In en, this message translates to:
  /// **'Cookies'**
  String get response_cookies;

  /// No description provided for @response_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get response_status;

  /// No description provided for @response_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get response_time;

  /// No description provided for @response_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get response_size;

  /// No description provided for @response_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get response_copy;

  /// No description provided for @response_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get response_save;

  /// No description provided for @response_noResponse.
  ///
  /// In en, this message translates to:
  /// **'Send a request to see the response'**
  String get response_noResponse;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_themeHint.
  ///
  /// In en, this message translates to:
  /// **'Follow system or switch manually'**
  String get settings_themeHint;

  /// No description provided for @settings_themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_themeLight;

  /// No description provided for @settings_themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_themeDark;

  /// No description provided for @settings_themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_themeSystem;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_languageHint.
  ///
  /// In en, this message translates to:
  /// **'UI display language, applies immediately'**
  String get settings_languageHint;

  /// No description provided for @settings_uiScale.
  ///
  /// In en, this message translates to:
  /// **'UI Scale'**
  String get settings_uiScale;

  /// No description provided for @settings_uiScaleHint.
  ///
  /// In en, this message translates to:
  /// **'Global text scaling for HiDPI screens'**
  String get settings_uiScaleHint;

  /// No description provided for @common_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get common_system;

  /// No description provided for @settings_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settings_english;

  /// No description provided for @settings_chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get settings_chinese;

  /// No description provided for @settings_editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settings_editor;

  /// No description provided for @settings_fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get settings_fontSize;

  /// No description provided for @settings_fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get settings_fontFamily;

  /// No description provided for @settings_network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get settings_network;

  /// No description provided for @settings_timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms)'**
  String get settings_timeout;

  /// No description provided for @settings_followRedirects.
  ///
  /// In en, this message translates to:
  /// **'Follow Redirects'**
  String get settings_followRedirects;

  /// No description provided for @settings_validateCertificates.
  ///
  /// In en, this message translates to:
  /// **'Validate Certificates'**
  String get settings_validateCertificates;

  /// No description provided for @status_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get status_ready;

  /// No description provided for @status_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get status_sending;

  /// No description provided for @status_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get status_error;

  /// No description provided for @sidebar_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {err}'**
  String sidebar_error(Object err);

  /// No description provided for @sidebar_themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get sidebar_themeSystem;

  /// No description provided for @sidebar_themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get sidebar_themeLight;

  /// No description provided for @sidebar_themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get sidebar_themeDark;

  /// No description provided for @sidebar_aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get sidebar_aiSettings;

  /// No description provided for @sidebar_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter...'**
  String get sidebar_searchHint;

  /// No description provided for @sidebar_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get sidebar_emptyTitle;

  /// No description provided for @sidebar_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collections group your API requests'**
  String get sidebar_emptySubtitle;

  /// No description provided for @sidebar_createCollection.
  ///
  /// In en, this message translates to:
  /// **'Create Collection'**
  String get sidebar_createCollection;

  /// No description provided for @sidebar_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get sidebar_rename;

  /// No description provided for @sidebar_deleteRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get sidebar_deleteRequestTitle;

  /// No description provided for @sidebar_deleteRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String sidebar_deleteRequestBody(Object name);

  /// No description provided for @sidebar_addRequest.
  ///
  /// In en, this message translates to:
  /// **'Add Request'**
  String get sidebar_addRequest;

  /// No description provided for @sidebar_addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get sidebar_addFolder;

  /// No description provided for @sidebar_folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get sidebar_folderNameHint;

  /// No description provided for @sidebar_collectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter collection name'**
  String get sidebar_collectionNameHint;

  /// No description provided for @sidebar_deleteCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get sidebar_deleteCollectionTitle;

  /// No description provided for @sidebar_deleteCollectionBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String sidebar_deleteCollectionBody(Object name);

  /// No description provided for @sidebar_importMenu.
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get sidebar_importMenu;

  /// No description provided for @sidebar_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get sidebar_refresh;

  /// No description provided for @sidebar_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sidebar_about;

  /// No description provided for @sidebar_aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Hop to your APIs'**
  String get sidebar_aboutTagline;

  /// No description provided for @sidebar_aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get sidebar_aboutVersion;

  /// No description provided for @sidebar_aboutPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get sidebar_aboutPlatform;

  /// No description provided for @sidebar_aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'Powered by AI · Built with Flutter'**
  String get sidebar_aboutFooter;

  /// No description provided for @sidebar_aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Hopp. All rights reserved.'**
  String get sidebar_aboutCopyright;

  /// No description provided for @sidebar_aboutMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get sidebar_aboutMoreInfo;

  /// No description provided for @viewer_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get viewer_copied;

  /// No description provided for @viewer_beautified.
  ///
  /// In en, this message translates to:
  /// **'Code beautified'**
  String get viewer_beautified;

  /// No description provided for @viewer_beautifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to beautify code'**
  String get viewer_beautifyFailed;

  /// No description provided for @viewer_sizeLines.
  ///
  /// In en, this message translates to:
  /// **'{size} • {lines} lines'**
  String viewer_sizeLines(Object lines, Object size);

  /// No description provided for @viewer_hideTimestamps.
  ///
  /// In en, this message translates to:
  /// **'Hide timestamp annotations'**
  String get viewer_hideTimestamps;

  /// No description provided for @viewer_showTimestamps.
  ///
  /// In en, this message translates to:
  /// **'Show timestamp annotations'**
  String get viewer_showTimestamps;

  /// No description provided for @viewer_beautify.
  ///
  /// In en, this message translates to:
  /// **'Beautify'**
  String get viewer_beautify;

  /// No description provided for @viewer_modePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get viewer_modePerformance;

  /// No description provided for @viewer_modeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get viewer_modeFull;

  /// No description provided for @viewer_showingLines.
  ///
  /// In en, this message translates to:
  /// **'Showing {displayed} of {total} lines'**
  String viewer_showingLines(Object displayed, Object total);

  /// No description provided for @viewer_loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load {remaining} more'**
  String viewer_loadMore(Object remaining);

  /// No description provided for @viewer_loadAll.
  ///
  /// In en, this message translates to:
  /// **'Load all'**
  String get viewer_loadAll;

  /// No description provided for @viewer_largeResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Large Response'**
  String get viewer_largeResponseTitle;

  /// No description provided for @viewer_largeResponseBody.
  ///
  /// In en, this message translates to:
  /// **'This response is {size} which may cause performance issues. Would you like to view it in performance mode?'**
  String viewer_largeResponseBody(Object size);

  /// No description provided for @viewer_viewFull.
  ///
  /// In en, this message translates to:
  /// **'View Full'**
  String get viewer_viewFull;

  /// No description provided for @viewer_performanceMode.
  ///
  /// In en, this message translates to:
  /// **'Performance Mode'**
  String get viewer_performanceMode;

  /// No description provided for @editor_enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text...'**
  String get editor_enterText;

  /// No description provided for @ai_configNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'AI configuration not loaded. Please try again later'**
  String get ai_configNotLoaded;

  /// No description provided for @ai_modelNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configure a local model (model name) in Settings first'**
  String get ai_modelNotConfigured;

  /// No description provided for @ai_noResponseSample.
  ///
  /// In en, this message translates to:
  /// **'Send a request or run it in Tests first'**
  String get ai_noResponseSample;

  /// No description provided for @ai_httpError.
  ///
  /// In en, this message translates to:
  /// **'Model service error: {message}'**
  String ai_httpError(Object message);

  /// No description provided for @ai_callFailed.
  ///
  /// In en, this message translates to:
  /// **'AI call failed: {error}'**
  String ai_callFailed(Object error);

  /// No description provided for @ai_connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Local model service not detected. Make sure Ollama / LM Studio is running'**
  String get ai_connectionFailed;

  /// No description provided for @ai_connectionFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'Local model service not detected. Make sure Ollama / LM Studio is running ({detail})'**
  String ai_connectionFailedDetail(Object detail);

  /// No description provided for @ai_timeout.
  ///
  /// In en, this message translates to:
  /// **'Local model timed out. It may be loading for the first time or the machine is busy. Please retry'**
  String get ai_timeout;

  /// No description provided for @ai_timeoutDetail.
  ///
  /// In en, this message translates to:
  /// **'Local model timed out. It may be loading for the first time or the machine is busy. Please retry ({detail})'**
  String ai_timeoutDetail(Object detail);

  /// No description provided for @ai_responseError.
  ///
  /// In en, this message translates to:
  /// **'The model service returned an unexpected response. Please try again later'**
  String get ai_responseError;

  /// No description provided for @ai_responseErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'The model service returned an unexpected response: {detail}'**
  String ai_responseErrorDetail(Object detail);

  /// No description provided for @ai_requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get ai_requestFailed;

  /// No description provided for @ai_responseNotJsonObject.
  ///
  /// In en, this message translates to:
  /// **'Response body is not a JSON object'**
  String get ai_responseNotJsonObject;

  /// No description provided for @ai_choicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'choices is empty'**
  String get ai_choicesEmpty;

  /// No description provided for @ai_choiceMessageMalformed.
  ///
  /// In en, this message translates to:
  /// **'Unexpected choices[0].message structure'**
  String get ai_choiceMessageMalformed;

  /// No description provided for @ai_choiceContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'choices[0].message.content is empty'**
  String get ai_choiceContentEmpty;

  /// No description provided for @ai_parseError.
  ///
  /// In en, this message translates to:
  /// **'AI returned an unexpected format. Please try again'**
  String get ai_parseError;

  /// No description provided for @request_preRequestChainFailed.
  ///
  /// In en, this message translates to:
  /// **'Pre-request chain failed: {error}'**
  String request_preRequestChainFailed(Object error);

  /// No description provided for @import_failed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get import_failed;

  /// No description provided for @import_failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String import_failedWithError(Object error);

  /// No description provided for @import_resolveConflictFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve conflict'**
  String get import_resolveConflictFailed;

  /// No description provided for @import_resolveConflictFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve conflict: {error}'**
  String import_resolveConflictFailedWithError(Object error);

  /// No description provided for @import_fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get import_fileNotFound;

  /// No description provided for @import_unknownFormat.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized file format. Make sure it is a valid Postman Collection or Environment'**
  String get import_unknownFormat;

  /// No description provided for @import_emptyCollection.
  ///
  /// In en, this message translates to:
  /// **'The imported collection contains no requests'**
  String get import_emptyCollection;

  /// No description provided for @import_invalidJson.
  ///
  /// In en, this message translates to:
  /// **'Could not parse the JSON file: {error}'**
  String import_invalidJson(Object error);

  /// No description provided for @import_invalidEnvironmentJson.
  ///
  /// In en, this message translates to:
  /// **'Could not parse the Environment file: {error}'**
  String import_invalidEnvironmentJson(Object error);

  /// No description provided for @import_unsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'Unsupported Postman Collection version: v1.0. Please upgrade to v2.0 or v2.1 format'**
  String get import_unsupportedVersion;

  /// No description provided for @import_environmentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported environment \"{name}\" ({count} variables)'**
  String import_environmentSuccess(Object count, Object name);

  /// No description provided for @import_existingCollectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find the existing collection'**
  String get import_existingCollectionNotFound;

  /// No description provided for @import_existingCollectionMissing.
  ///
  /// In en, this message translates to:
  /// **'The existing collection no longer exists'**
  String get import_existingCollectionMissing;

  /// No description provided for @export_failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String export_failedWithError(Object error);

  /// No description provided for @export_collectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Collection not found: {id}'**
  String export_collectionNotFound(Object id);

  /// No description provided for @openapi_unknownFormat.
  ///
  /// In en, this message translates to:
  /// **'Not recognized as an OpenAPI/Swagger document'**
  String get openapi_unknownFormat;

  /// No description provided for @openapi_missingPaths.
  ///
  /// In en, this message translates to:
  /// **'Not recognized as an OpenAPI/Swagger document: missing paths'**
  String get openapi_missingPaths;

  /// No description provided for @openapi_fetchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fetch failed: response body is empty'**
  String get openapi_fetchEmpty;

  /// No description provided for @openapi_fetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Fetch failed: {error}'**
  String openapi_fetchFailed(Object error);

  /// No description provided for @openapi_noOperations.
  ///
  /// In en, this message translates to:
  /// **'The document contains no importable operations'**
  String get openapi_noOperations;

  /// No description provided for @openapi_conflictResolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve conflict'**
  String get openapi_conflictResolveFailed;

  /// No description provided for @openapi_noSource.
  ///
  /// In en, this message translates to:
  /// **'No import source provided (one of filePath / url / content)'**
  String get openapi_noSource;

  /// No description provided for @openapi_parseFailed.
  ///
  /// In en, this message translates to:
  /// **'Parse failed: {error}'**
  String openapi_parseFailed(Object error);

  /// No description provided for @openapi_placeholderFormData.
  ///
  /// In en, this message translates to:
  /// **'Form fields generated from schema — review and fill in'**
  String get openapi_placeholderFormData;

  /// No description provided for @openapi_placeholderBody.
  ///
  /// In en, this message translates to:
  /// **'Body generated from schema skeleton — review and fill in'**
  String get openapi_placeholderBody;

  /// No description provided for @openapi_authBearer.
  ///
  /// In en, this message translates to:
  /// **'Bearer Token (fill in token)'**
  String get openapi_authBearer;

  /// No description provided for @openapi_authBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic Auth (fill in username/password)'**
  String get openapi_authBasic;

  /// No description provided for @openapi_authApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key ({where}: {name} — fill in the key)'**
  String openapi_authApiKey(Object name, Object where);

  /// No description provided for @curl_emptyInput.
  ///
  /// In en, this message translates to:
  /// **'Please enter a cURL command'**
  String get curl_emptyInput;

  /// No description provided for @curl_invalidCommand.
  ///
  /// In en, this message translates to:
  /// **'Invalid cURL command. Must start with \"curl\"'**
  String get curl_invalidCommand;

  /// No description provided for @curl_unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get curl_unknownError;

  /// No description provided for @curl_parseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse cURL command: {error}'**
  String curl_parseFailed(Object error);

  /// No description provided for @curl_unsupportedOption.
  ///
  /// In en, this message translates to:
  /// **'Unsupported option: -{option}'**
  String curl_unsupportedOption(Object option);

  /// No description provided for @collection_saveNoCollection.
  ///
  /// In en, this message translates to:
  /// **'Failed to create or find a collection to save the request.'**
  String get collection_saveNoCollection;

  /// No description provided for @collection_notLoaded.
  ///
  /// In en, this message translates to:
  /// **'Collections not loaded yet'**
  String get collection_notLoaded;

  /// No description provided for @collectionSettings_title.
  ///
  /// In en, this message translates to:
  /// **'{name} · Settings'**
  String collectionSettings_title(Object name);

  /// No description provided for @collectionSettings_sectionHeader.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION'**
  String get collectionSettings_sectionHeader;

  /// No description provided for @collectionSettings_navGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get collectionSettings_navGeneral;

  /// No description provided for @collectionSettings_navPreRequest.
  ///
  /// In en, this message translates to:
  /// **'Pre-request'**
  String get collectionSettings_navPreRequest;

  /// No description provided for @collectionSettings_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get collectionSettings_nameLabel;

  /// No description provided for @collectionSettings_descLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get collectionSettings_descLabel;

  /// No description provided for @collectionSettings_descHint.
  ///
  /// In en, this message translates to:
  /// **'Optional description'**
  String get collectionSettings_descHint;

  /// No description provided for @collectionSettings_inheritFrom.
  ///
  /// In en, this message translates to:
  /// **'Inherited from parent collection \"{name}\". Change it in that collection\'s settings.'**
  String collectionSettings_inheritFrom(Object name);

  /// No description provided for @collectionSettings_inheritNoAuth.
  ///
  /// In en, this message translates to:
  /// **'Inherited from parent collection \"{name}\": No Auth.'**
  String collectionSettings_inheritNoAuth(Object name);

  /// No description provided for @collectionSettings_rootInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit on a root collection is equivalent to No Auth; no credentials are sent.'**
  String get collectionSettings_rootInherit;

  /// No description provided for @import_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get import_done;

  /// No description provided for @import_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get import_retry;

  /// No description provided for @import_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get import_back;

  /// No description provided for @import_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get import_importing;

  /// No description provided for @import_failedTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get import_failedTitle;

  /// No description provided for @import_successTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Successful'**
  String get import_successTitle;

  /// No description provided for @import_successRenamed.
  ///
  /// In en, this message translates to:
  /// **'Collection renamed to: {name}'**
  String import_successRenamed(Object name);

  /// No description provided for @import_successMerged.
  ///
  /// In en, this message translates to:
  /// **'Collection merged with existing collection'**
  String get import_successMerged;

  /// No description provided for @import_successCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} requests'**
  String import_successCount(Object count);

  /// No description provided for @import_dropZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Click to select file or drag and drop here'**
  String get import_dropZoneHint;

  /// No description provided for @import_dropZoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Supports Postman Collection v2.0/v2.1 and Environment'**
  String get import_dropZoneSupport;

  /// No description provided for @import_selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get import_selectFile;

  /// No description provided for @import_parse.
  ///
  /// In en, this message translates to:
  /// **'Parse'**
  String get import_parse;

  /// No description provided for @import_importRequest.
  ///
  /// In en, this message translates to:
  /// **'Import {count} request'**
  String import_importRequest(Object count);

  /// No description provided for @import_importRequests.
  ///
  /// In en, this message translates to:
  /// **'Import {count} requests'**
  String import_importRequests(Object count);

  /// No description provided for @import_openCollection.
  ///
  /// In en, this message translates to:
  /// **'Open collection'**
  String get import_openCollection;

  /// No description provided for @import_previewStats.
  ///
  /// In en, this message translates to:
  /// **'Selected {selected} / {total} · 1 collection + {subCount} sub-collections'**
  String import_previewStats(Object selected, Object subCount, Object total);

  /// No description provided for @import_unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get import_unknownError;

  /// No description provided for @import_selectCollection.
  ///
  /// In en, this message translates to:
  /// **'Select Collection'**
  String get import_selectCollection;

  /// No description provided for @conflict_title.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" Already Exists'**
  String conflict_title(Object name);

  /// No description provided for @conflict_prompt.
  ///
  /// In en, this message translates to:
  /// **'Please choose how to handle this:'**
  String get conflict_prompt;

  /// No description provided for @conflict_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename Import'**
  String get conflict_rename;

  /// No description provided for @conflict_renameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rename imported collection to \"{name} (1)\"'**
  String conflict_renameSubtitle(Object name);

  /// No description provided for @conflict_overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite Existing'**
  String get conflict_overwrite;

  /// No description provided for @conflict_overwriteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace existing collection with imported content'**
  String get conflict_overwriteSubtitle;

  /// No description provided for @conflict_merge.
  ///
  /// In en, this message translates to:
  /// **'Merge Collections'**
  String get conflict_merge;

  /// No description provided for @conflict_mergeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep existing requests and add new ones'**
  String get conflict_mergeSubtitle;

  /// No description provided for @conflict_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get conflict_skip;

  /// No description provided for @conflict_skipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel import for this collection'**
  String get conflict_skipSubtitle;

  /// No description provided for @conflict_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get conflict_confirm;

  /// No description provided for @conflict_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Collection Name'**
  String get conflict_dialogTitle;

  /// No description provided for @conflict_dialogMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists. Please choose how to handle this:'**
  String conflict_dialogMessage(Object name);

  /// No description provided for @conflict_skipThis.
  ///
  /// In en, this message translates to:
  /// **'Skip This Collection'**
  String get conflict_skipThis;

  /// No description provided for @conflict_applyToAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all conflicts'**
  String get conflict_applyToAll;

  /// No description provided for @export_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load collection list'**
  String get export_loadFailed;

  /// No description provided for @export_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get export_exporting;

  /// No description provided for @export_exportingCollection.
  ///
  /// In en, this message translates to:
  /// **'Exporting collection...'**
  String get export_exportingCollection;

  /// No description provided for @export_successTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Successful'**
  String get export_successTitle;

  /// No description provided for @export_savedTo.
  ///
  /// In en, this message translates to:
  /// **'File saved to:'**
  String get export_savedTo;

  /// No description provided for @export_failedTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Failed'**
  String get export_failedTitle;

  /// No description provided for @export_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Collection'**
  String get export_dialogTitle;

  /// No description provided for @export_formatHeader.
  ///
  /// In en, this message translates to:
  /// **'FORMAT'**
  String get export_formatHeader;

  /// No description provided for @export_formatPostman.
  ///
  /// In en, this message translates to:
  /// **'Postman Collection'**
  String get export_formatPostman;

  /// No description provided for @export_formatPostmanDesc1.
  ///
  /// In en, this message translates to:
  /// **'Interchange with Postman / other tools. Assertions and pre-request chains are '**
  String get export_formatPostmanDesc1;

  /// No description provided for @export_formatPostmanDescNot.
  ///
  /// In en, this message translates to:
  /// **'not'**
  String get export_formatPostmanDescNot;

  /// No description provided for @export_formatPostmanDesc2.
  ///
  /// In en, this message translates to:
  /// **' included (format cannot express them).'**
  String get export_formatPostmanDesc2;

  /// No description provided for @export_formatHoppDesc1.
  ///
  /// In en, this message translates to:
  /// **'Full fidelity: assertions, pre-request chains, auth and variable pipelines. Run in CI with '**
  String get export_formatHoppDesc1;

  /// No description provided for @export_formatHoppDesc2.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get export_formatHoppDesc2;

  /// No description provided for @export_secretNotice1.
  ///
  /// In en, this message translates to:
  /// **'Secret variable values are exported empty. Inject them in CI with '**
  String get export_secretNotice1;

  /// No description provided for @export_secretNotice2.
  ///
  /// In en, this message translates to:
  /// **' or process environment variables.'**
  String get export_secretNotice2;

  /// No description provided for @export_formatVersion.
  ///
  /// In en, this message translates to:
  /// **'Format Version'**
  String get export_formatVersion;

  /// No description provided for @export_prettify.
  ///
  /// In en, this message translates to:
  /// **'Prettify JSON Output'**
  String get export_prettify;

  /// No description provided for @export_prettifyHint.
  ///
  /// In en, this message translates to:
  /// **'Format with indentation for readability'**
  String get export_prettifyHint;

  /// No description provided for @export_saveHoppTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Hopp CLI Collection'**
  String get export_saveHoppTitle;

  /// No description provided for @export_savePostmanTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Postman Collection'**
  String get export_savePostmanTitle;

  /// No description provided for @curl_importAndSend.
  ///
  /// In en, this message translates to:
  /// **'Import & Send'**
  String get curl_importAndSend;

  /// No description provided for @curl_commandLabel.
  ///
  /// In en, this message translates to:
  /// **'cURL Command'**
  String get curl_commandLabel;

  /// No description provided for @curl_paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get curl_paste;

  /// No description provided for @curl_emptyPreview.
  ///
  /// In en, this message translates to:
  /// **'Parsed request will appear here'**
  String get curl_emptyPreview;

  /// No description provided for @curl_parsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing...'**
  String get curl_parsing;

  /// No description provided for @curl_parseError.
  ///
  /// In en, this message translates to:
  /// **'Parse Error'**
  String get curl_parseError;

  /// No description provided for @curl_parsedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Parsed Successfully'**
  String get curl_parsedSuccess;

  /// No description provided for @curl_warningCountOne.
  ///
  /// In en, this message translates to:
  /// **'{count} warning'**
  String curl_warningCountOne(Object count);

  /// No description provided for @curl_warningCountMany.
  ///
  /// In en, this message translates to:
  /// **'{count} warnings'**
  String curl_warningCountMany(Object count);

  /// No description provided for @curl_labelMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get curl_labelMethod;

  /// No description provided for @curl_labelUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get curl_labelUrl;

  /// No description provided for @curl_headersEnabled.
  ///
  /// In en, this message translates to:
  /// **'{count} enabled'**
  String curl_headersEnabled(Object count);

  /// No description provided for @curl_labelBodyType.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get curl_labelBodyType;

  /// No description provided for @curl_labelBodySize.
  ///
  /// In en, this message translates to:
  /// **'Body Size'**
  String get curl_labelBodySize;

  /// No description provided for @curl_bodyBytes.
  ///
  /// In en, this message translates to:
  /// **'{count} bytes'**
  String curl_bodyBytes(Object count);

  /// No description provided for @curl_sslVerifyOff.
  ///
  /// In en, this message translates to:
  /// **'SSL verify: OFF'**
  String get curl_sslVerifyOff;

  /// No description provided for @curl_followRedirectsOn.
  ///
  /// In en, this message translates to:
  /// **'Follow redirects: ON'**
  String get curl_followRedirectsOn;

  /// No description provided for @curl_warningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Warnings:'**
  String get curl_warningsLabel;

  /// No description provided for @curl_requestNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter request name...'**
  String get curl_requestNameHint;

  /// No description provided for @curl_noCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections available. Please create a collection first.'**
  String get curl_noCollections;

  /// No description provided for @curl_saveToCollection.
  ///
  /// In en, this message translates to:
  /// **'Save to Collection'**
  String get curl_saveToCollection;

  /// No description provided for @curl_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load collections'**
  String get curl_loadFailed;

  /// No description provided for @openapi_parsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing spec…'**
  String get openapi_parsing;

  /// No description provided for @openapi_importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get openapi_importing;

  /// No description provided for @openapi_dropZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Click to select a spec file'**
  String get openapi_dropZoneHint;

  /// No description provided for @openapi_dropZoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Supports .json / .yaml / .yml · OpenAPI 3.x · Swagger 2.0'**
  String get openapi_dropZoneSupport;

  /// No description provided for @openapi_orFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Or import from URL'**
  String get openapi_orFromUrl;

  /// No description provided for @openapi_specUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Spec URL'**
  String get openapi_specUrlLabel;

  /// No description provided for @openapi_specUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Machine-readable address (openapi.json / swagger.yaml), parsed locally — data never leaves your machine.'**
  String get openapi_specUrlHint;

  /// No description provided for @openapi_headerLabel.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get openapi_headerLabel;

  /// No description provided for @openapi_headerHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. One custom header used only for this fetch (private specs). Not saved.'**
  String get openapi_headerHint;

  /// No description provided for @openapi_specSummary.
  ///
  /// In en, this message translates to:
  /// **' · OpenAPI {version} · {tagCount} tags · {opCount} operations'**
  String openapi_specSummary(Object opCount, Object tagCount, Object version);

  /// No description provided for @openapi_serverLabel.
  ///
  /// In en, this message translates to:
  /// **' · Server '**
  String get openapi_serverLabel;

  /// No description provided for @openapi_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search path or name…'**
  String get openapi_searchHint;

  /// No description provided for @openapi_selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get openapi_selectAll;

  /// No description provided for @openapi_selectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get openapi_selectNone;

  /// No description provided for @openapi_noMatch.
  ///
  /// In en, this message translates to:
  /// **'No operations match your search'**
  String get openapi_noMatch;

  /// No description provided for @openapi_noTag.
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get openapi_noTag;

  /// No description provided for @openapi_statRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests imported'**
  String get openapi_statRequests;

  /// No description provided for @openapi_statPlaceholders.
  ///
  /// In en, this message translates to:
  /// **'Placeholders'**
  String get openapi_statPlaceholders;

  /// No description provided for @openapi_importedAs.
  ///
  /// In en, this message translates to:
  /// **'Imported as \"{name}\"'**
  String openapi_importedAs(Object name);

  /// No description provided for @openapi_mergedInto.
  ///
  /// In en, this message translates to:
  /// **'Merged into existing collection \"{name}\"'**
  String openapi_mergedInto(Object name);

  /// No description provided for @openapi_placeholdersHeader.
  ///
  /// In en, this message translates to:
  /// **'PLACEHOLDERS (VALUES FROM SCHEMA SKELETON, NOT SPEC EXAMPLES)'**
  String get openapi_placeholdersHeader;

  /// No description provided for @openapi_oauthNotice.
  ///
  /// In en, this message translates to:
  /// **'OAuth2 / OpenID Connect scheme(s) {schemes} were not configured automatically. Go to Collection settings → Auth to complete the authorization flow.'**
  String openapi_oauthNotice(Object schemes);

  /// No description provided for @openapi_authConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured collection-level Auth: {description}.'**
  String openapi_authConfigured(Object description);

  /// No description provided for @curl_inputHint.
  ///
  /// In en, this message translates to:
  /// **'Paste cURL command here...'**
  String get curl_inputHint;

  /// No description provided for @curl_inputHintExample.
  ///
  /// In en, this message translates to:
  /// **'Example:'**
  String get curl_inputHintExample;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get common_show;

  /// No description provided for @common_hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get common_hide;

  /// No description provided for @request_selectRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a request'**
  String get request_selectRequestTitle;

  /// No description provided for @request_selectRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a request from the sidebar or create a new one'**
  String get request_selectRequestSubtitle;

  /// No description provided for @request_unresolvedVariables.
  ///
  /// In en, this message translates to:
  /// **'Unresolved variables: {variables}'**
  String request_unresolvedVariables(Object variables);

  /// No description provided for @request_tabPreRequest.
  ///
  /// In en, this message translates to:
  /// **'Pre-request'**
  String get request_tabPreRequest;

  /// No description provided for @request_tabAssertions.
  ///
  /// In en, this message translates to:
  /// **'Assertions'**
  String get request_tabAssertions;

  /// No description provided for @request_keyColumn.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get request_keyColumn;

  /// No description provided for @request_valueColumn.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get request_valueColumn;

  /// No description provided for @request_descriptionColumn.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get request_descriptionColumn;

  /// No description provided for @request_addNewRow.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get request_addNewRow;

  /// No description provided for @request_noBodyContent.
  ///
  /// In en, this message translates to:
  /// **'No body content'**
  String get request_noBodyContent;

  /// No description provided for @request_selectBodyTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select a body type to add content'**
  String get request_selectBodyTypeHint;

  /// No description provided for @request_formDataComingSoon.
  ///
  /// In en, this message translates to:
  /// **'form-data editor (coming soon)'**
  String get request_formDataComingSoon;

  /// No description provided for @request_urlEncodedComingSoon.
  ///
  /// In en, this message translates to:
  /// **'x-www-form-urlencoded editor (coming soon)'**
  String get request_urlEncodedComingSoon;

  /// No description provided for @request_bodySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'BODY'**
  String get request_bodySectionTitle;

  /// No description provided for @request_selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select file'**
  String get request_selectFile;

  /// No description provided for @request_chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get request_chooseFile;

  /// No description provided for @request_graphqlComingSoon.
  ///
  /// In en, this message translates to:
  /// **'GraphQL editor (coming soon)'**
  String get request_graphqlComingSoon;

  /// No description provided for @request_inheritSummaryNoAuth.
  ///
  /// In en, this message translates to:
  /// **'Inherited from collection \"{name}\": No Auth — no credentials will be sent.'**
  String request_inheritSummaryNoAuth(Object name);

  /// No description provided for @request_inheritSummary.
  ///
  /// In en, this message translates to:
  /// **'Inherited from collection \"{name}\": {authType}. Edit it in collection settings.'**
  String request_inheritSummary(Object authType, Object name);

  /// No description provided for @request_sslVerification.
  ///
  /// In en, this message translates to:
  /// **'Enable SSL certificate verification'**
  String get request_sslVerification;

  /// No description provided for @request_sslVerificationHint.
  ///
  /// In en, this message translates to:
  /// **'Verify the server\'s SSL certificate chain'**
  String get request_sslVerificationHint;

  /// No description provided for @request_sslDisableNote.
  ///
  /// In en, this message translates to:
  /// **'Disable this option to allow self-signed certificates or bypass certificate errors for testing purposes.'**
  String get request_sslDisableNote;

  /// No description provided for @request_redirectsSection.
  ///
  /// In en, this message translates to:
  /// **'Redirects'**
  String get request_redirectsSection;

  /// No description provided for @request_followRedirects.
  ///
  /// In en, this message translates to:
  /// **'Follow redirects'**
  String get request_followRedirects;

  /// No description provided for @request_followRedirectsHint.
  ///
  /// In en, this message translates to:
  /// **'Automatically follow HTTP 3xx redirects'**
  String get request_followRedirectsHint;

  /// No description provided for @request_maxRedirects.
  ///
  /// In en, this message translates to:
  /// **'Maximum redirects'**
  String get request_maxRedirects;

  /// No description provided for @request_maxRedirectsHint.
  ///
  /// In en, this message translates to:
  /// **'Limit the number of redirects to follow (0 = unlimited)'**
  String get request_maxRedirectsHint;

  /// No description provided for @request_comingSoonSection.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get request_comingSoonSection;

  /// No description provided for @request_timeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get request_timeoutTitle;

  /// No description provided for @request_timeoutHint.
  ///
  /// In en, this message translates to:
  /// **'Set the request timeout duration'**
  String get request_timeoutHint;

  /// No description provided for @request_savedToCollection.
  ///
  /// In en, this message translates to:
  /// **'Request saved to collection'**
  String get request_savedToCollection;

  /// No description provided for @request_saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save request'**
  String get request_saveFailed;

  /// No description provided for @request_saveFailedCollection.
  ///
  /// In en, this message translates to:
  /// **'Unable to save: Collection error. Please try again.'**
  String get request_saveFailedCollection;

  /// No description provided for @request_headerDescAccept.
  ///
  /// In en, this message translates to:
  /// **'Media types that are acceptable for the response'**
  String get request_headerDescAccept;

  /// No description provided for @request_headerDescAcceptCharset.
  ///
  /// In en, this message translates to:
  /// **'Character sets that are acceptable'**
  String get request_headerDescAcceptCharset;

  /// No description provided for @request_headerDescAcceptEncoding.
  ///
  /// In en, this message translates to:
  /// **'List of acceptable encodings (gzip, deflate, br)'**
  String get request_headerDescAcceptEncoding;

  /// No description provided for @request_headerDescAcceptLanguage.
  ///
  /// In en, this message translates to:
  /// **'List of acceptable human languages'**
  String get request_headerDescAcceptLanguage;

  /// No description provided for @request_headerDescAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Authentication credentials (Bearer token, Basic auth)'**
  String get request_headerDescAuthorization;

  /// No description provided for @request_headerDescCacheControl.
  ///
  /// In en, this message translates to:
  /// **'Directives for caching mechanisms'**
  String get request_headerDescCacheControl;

  /// No description provided for @request_headerDescConnection.
  ///
  /// In en, this message translates to:
  /// **'Control options for the current connection (keep-alive)'**
  String get request_headerDescConnection;

  /// No description provided for @request_headerDescContentLength.
  ///
  /// In en, this message translates to:
  /// **'The length of the request body in octets'**
  String get request_headerDescContentLength;

  /// No description provided for @request_headerDescContentType.
  ///
  /// In en, this message translates to:
  /// **'The MIME type of the body (application/json)'**
  String get request_headerDescContentType;

  /// No description provided for @request_headerDescCookie.
  ///
  /// In en, this message translates to:
  /// **'An HTTP cookie previously sent by the server'**
  String get request_headerDescCookie;

  /// No description provided for @request_headerDescHost.
  ///
  /// In en, this message translates to:
  /// **'The domain name of the server (and optional port)'**
  String get request_headerDescHost;

  /// No description provided for @request_headerDescOrigin.
  ///
  /// In en, this message translates to:
  /// **'Indicates where a fetch originates from'**
  String get request_headerDescOrigin;

  /// No description provided for @request_headerDescReferer.
  ///
  /// In en, this message translates to:
  /// **'The address of the previous web page'**
  String get request_headerDescReferer;

  /// No description provided for @request_headerDescUserAgent.
  ///
  /// In en, this message translates to:
  /// **'The user agent string of the client'**
  String get request_headerDescUserAgent;

  /// No description provided for @request_headerDescXRequestedWith.
  ///
  /// In en, this message translates to:
  /// **'Used to identify AJAX requests'**
  String get request_headerDescXRequestedWith;

  /// No description provided for @assertion_targetStatus.
  ///
  /// In en, this message translates to:
  /// **'Status code'**
  String get assertion_targetStatus;

  /// No description provided for @assertion_targetHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get assertion_targetHeader;

  /// No description provided for @assertion_targetBody.
  ///
  /// In en, this message translates to:
  /// **'Body text'**
  String get assertion_targetBody;

  /// No description provided for @assertion_targetJsonPath.
  ///
  /// In en, this message translates to:
  /// **'JSONPath'**
  String get assertion_targetJsonPath;

  /// No description provided for @assertion_targetResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Response time'**
  String get assertion_targetResponseTime;

  /// No description provided for @assertion_title.
  ///
  /// In en, this message translates to:
  /// **'Response assertions'**
  String get assertion_title;

  /// No description provided for @assertion_noteEvaluated.
  ///
  /// In en, this message translates to:
  /// **'Evaluated after every send. '**
  String get assertion_noteEvaluated;

  /// No description provided for @assertion_noteExpectedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Expected values support '**
  String get assertion_noteExpectedPrefix;

  /// No description provided for @assertion_noteExpectedSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get assertion_noteExpectedSuffix;

  /// No description provided for @assertion_add.
  ///
  /// In en, this message translates to:
  /// **'Add assertion'**
  String get assertion_add;

  /// No description provided for @assertion_colTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get assertion_colTarget;

  /// No description provided for @assertion_colNamePath.
  ///
  /// In en, this message translates to:
  /// **'NAME / PATH'**
  String get assertion_colNamePath;

  /// No description provided for @assertion_colOperator.
  ///
  /// In en, this message translates to:
  /// **'OPERATOR'**
  String get assertion_colOperator;

  /// No description provided for @assertion_colExpected.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED'**
  String get assertion_colExpected;

  /// No description provided for @assertion_headerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Header name'**
  String get assertion_headerNameHint;

  /// No description provided for @assertion_expectedHint.
  ///
  /// In en, this message translates to:
  /// **'Expected value'**
  String get assertion_expectedHint;

  /// No description provided for @assertion_hintPrefix.
  ///
  /// In en, this message translates to:
  /// **'Operators are filtered by target — e.g. '**
  String get assertion_hintPrefix;

  /// No description provided for @assertion_hintNoExpected.
  ///
  /// In en, this message translates to:
  /// **' needs no expected value; '**
  String get assertion_hintNoExpected;

  /// No description provided for @assertion_hintComparison.
  ///
  /// In en, this message translates to:
  /// **' apply to Status code / Response time. Response time is in milliseconds.'**
  String get assertion_hintComparison;

  /// No description provided for @assertion_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No assertions yet'**
  String get assertion_emptyTitle;

  /// No description provided for @assertion_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add one to validate the response after every send'**
  String get assertion_emptySubtitle;

  /// No description provided for @auth_typeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'AUTH TYPE'**
  String get auth_typeSectionTitle;

  /// No description provided for @auth_typeInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get auth_typeInherit;

  /// No description provided for @auth_typeNone.
  ///
  /// In en, this message translates to:
  /// **'No Auth'**
  String get auth_typeNone;

  /// No description provided for @auth_typeBearer.
  ///
  /// In en, this message translates to:
  /// **'Bearer Token'**
  String get auth_typeBearer;

  /// No description provided for @auth_typeBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic Auth'**
  String get auth_typeBasic;

  /// No description provided for @auth_typeApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get auth_typeApiKey;

  /// No description provided for @auth_inheritDesc.
  ///
  /// In en, this message translates to:
  /// **'Follows the auth configuration of the parent collection.'**
  String get auth_inheritDesc;

  /// No description provided for @auth_inheritNotFound.
  ///
  /// In en, this message translates to:
  /// **'No auth configuration found in the inheritance chain; no credentials will be sent.'**
  String get auth_inheritNotFound;

  /// No description provided for @auth_noneDesc.
  ///
  /// In en, this message translates to:
  /// **'No credentials are sent, and inheritance from the collection is blocked.'**
  String get auth_noneDesc;

  /// No description provided for @auth_bearerDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically attaches Authorization: Bearer <token> when sending; any same-name header is overridden.'**
  String get auth_bearerDesc;

  /// No description provided for @auth_tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get auth_tokenLabel;

  /// No description provided for @auth_basicDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically attaches Authorization: Basic base64(user:pass) when sending.'**
  String get auth_basicDesc;

  /// No description provided for @auth_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get auth_username;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_apiKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Injects a custom key into a header or query params.'**
  String get auth_apiKeyDesc;

  /// No description provided for @auth_keyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get auth_keyLabel;

  /// No description provided for @auth_addTo.
  ///
  /// In en, this message translates to:
  /// **'Add to'**
  String get auth_addTo;

  /// No description provided for @auth_addToHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get auth_addToHeader;

  /// No description provided for @auth_addToQuery.
  ///
  /// In en, this message translates to:
  /// **'Query Params'**
  String get auth_addToQuery;

  /// No description provided for @auth_variableHint.
  ///
  /// In en, this message translates to:
  /// **'All fields support {variable} and transform pipelines (e.g. {example}).'**
  String auth_variableHint(Object example, Object variable);

  /// No description provided for @prerequest_title.
  ///
  /// In en, this message translates to:
  /// **'Pre-request Chain'**
  String get prerequest_title;

  /// No description provided for @prerequest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Executed in order before this request is sent; variables produced by steps go to the local scope, valid only for this session and do not pollute environments'**
  String get prerequest_subtitle;

  /// No description provided for @prerequest_addStep.
  ///
  /// In en, this message translates to:
  /// **'Add Step'**
  String get prerequest_addStep;

  /// No description provided for @prerequest_testRun.
  ///
  /// In en, this message translates to:
  /// **'Test Run'**
  String get prerequest_testRun;

  /// No description provided for @prerequest_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No pre-request steps yet'**
  String get prerequest_emptyTitle;

  /// No description provided for @prerequest_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Typical scenario: run a login request first, then extract {token} from the response'**
  String prerequest_emptyHint(Object token);

  /// No description provided for @prerequest_selectRequest.
  ///
  /// In en, this message translates to:
  /// **'Select request…'**
  String get prerequest_selectRequest;

  /// No description provided for @prerequest_requestDeleted.
  ///
  /// In en, this message translates to:
  /// **'The referenced request has been deleted'**
  String get prerequest_requestDeleted;

  /// No description provided for @prerequest_deleteStep.
  ///
  /// In en, this message translates to:
  /// **'Delete step'**
  String get prerequest_deleteStep;

  /// No description provided for @prerequest_extractHeader.
  ///
  /// In en, this message translates to:
  /// **'EXTRACT · Extract variables from response'**
  String get prerequest_extractHeader;

  /// No description provided for @prerequest_sourceJsonPath.
  ///
  /// In en, this message translates to:
  /// **'Body · JSONPath'**
  String get prerequest_sourceJsonPath;

  /// No description provided for @prerequest_sourceHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get prerequest_sourceHeader;

  /// No description provided for @prerequest_sourceRegex.
  ///
  /// In en, this message translates to:
  /// **'Body · Regex'**
  String get prerequest_sourceRegex;

  /// No description provided for @prerequest_deleteRule.
  ///
  /// In en, this message translates to:
  /// **'Delete rule'**
  String get prerequest_deleteRule;

  /// No description provided for @prerequest_addRule.
  ///
  /// In en, this message translates to:
  /// **'Add extraction rule'**
  String get prerequest_addRule;

  /// No description provided for @prerequest_policyTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiration Policy'**
  String get prerequest_policyTitle;

  /// No description provided for @prerequest_retry401Hint.
  ///
  /// In en, this message translates to:
  /// **'Automatically re-run the chain on 401 (off = resend manually after sending)'**
  String get prerequest_retry401Hint;

  /// No description provided for @prerequest_scopeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chain variables go to the local scope (session-level) and do not pollute environments'**
  String get prerequest_scopeTooltip;

  /// No description provided for @prerequest_scopeLocal.
  ///
  /// In en, this message translates to:
  /// **'Variable scope: Local'**
  String get prerequest_scopeLocal;

  /// No description provided for @prerequest_resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Run Results'**
  String get prerequest_resultTitle;

  /// No description provided for @prerequest_allSucceeded.
  ///
  /// In en, this message translates to:
  /// **'All steps succeeded'**
  String get prerequest_allSucceeded;

  /// No description provided for @prerequest_someStepsFailed.
  ///
  /// In en, this message translates to:
  /// **'Some steps failed'**
  String get prerequest_someStepsFailed;

  /// No description provided for @prerequest_noVariables.
  ///
  /// In en, this message translates to:
  /// **'No variables produced (check extraction rules)'**
  String get prerequest_noVariables;

  /// No description provided for @prerequest_stepN.
  ///
  /// In en, this message translates to:
  /// **'Step {index}'**
  String prerequest_stepN(Object index);

  /// No description provided for @prerequest_missingValue.
  ///
  /// In en, this message translates to:
  /// **'{path} → {variable}: no value extracted'**
  String prerequest_missingValue(Object path, Object variable);

  /// No description provided for @fx_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Variable preview & transform functions'**
  String get fx_tooltip;

  /// No description provided for @fx_resolvedPreview.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED PREVIEW'**
  String get fx_resolvedPreview;

  /// No description provided for @fx_insertDynamicVariable.
  ///
  /// In en, this message translates to:
  /// **'INSERT DYNAMIC VARIABLE'**
  String get fx_insertDynamicVariable;

  /// No description provided for @fx_insertTransform.
  ///
  /// In en, this message translates to:
  /// **'INSERT TRANSFORM'**
  String get fx_insertTransform;

  /// No description provided for @fx_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Type {variable} to preview resolved values here'**
  String fx_emptyHint(Object variable);

  /// No description provided for @fx_undefined.
  ///
  /// In en, this message translates to:
  /// **'(undefined)'**
  String get fx_undefined;

  /// No description provided for @fx_transformFailed.
  ///
  /// In en, this message translates to:
  /// **'(transform failed)'**
  String get fx_transformFailed;

  /// No description provided for @fx_dateAddFormatError.
  ///
  /// In en, this message translates to:
  /// **'Format: [+-]integer + unit (s/m/h/d/w), e.g. -7d'**
  String get fx_dateAddFormatError;

  /// No description provided for @fx_dateAddUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Units: s seconds / m minutes / h hours / d days / w weeks; base is a 10-digit seconds or 13-digit milliseconds epoch.'**
  String get fx_dateAddUnitHint;

  /// No description provided for @fx_floorHour.
  ///
  /// In en, this message translates to:
  /// **'hour · start of current hour'**
  String get fx_floorHour;

  /// No description provided for @fx_floorDay.
  ///
  /// In en, this message translates to:
  /// **'day · start of today'**
  String get fx_floorDay;

  /// No description provided for @fx_floorWeek.
  ///
  /// In en, this message translates to:
  /// **'week · start of this Monday'**
  String get fx_floorWeek;

  /// No description provided for @fx_floorMonth.
  ///
  /// In en, this message translates to:
  /// **'month · start of the 1st of this month'**
  String get fx_floorMonth;

  /// No description provided for @fx_dateFloorHint.
  ///
  /// In en, this message translates to:
  /// **'Floored in the local timezone; base is a 10-digit seconds or 13-digit milliseconds epoch, output keeps the same unit.'**
  String get fx_dateFloorHint;

  /// No description provided for @fx_insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get fx_insert;

  /// No description provided for @fx_aesKeyHint.
  ///
  /// In en, this message translates to:
  /// **'{sample} · 16/24/32 bytes'**
  String fx_aesKeyHint(Object sample);

  /// No description provided for @fx_aesIvHint.
  ///
  /// In en, this message translates to:
  /// **'{sample} · cbc requires 16 bytes'**
  String fx_aesIvHint(Object sample);

  /// No description provided for @fx_paramVariableHint.
  ///
  /// In en, this message translates to:
  /// **'Parameters support {variable} references.'**
  String fx_paramVariableHint(Object variable);

  /// No description provided for @response_noResponseYet.
  ///
  /// In en, this message translates to:
  /// **'No response yet'**
  String get response_noResponseYet;

  /// No description provided for @response_copyResponse.
  ///
  /// In en, this message translates to:
  /// **'Copy response'**
  String get response_copyResponse;

  /// No description provided for @response_saveResponse.
  ///
  /// In en, this message translates to:
  /// **'Save response'**
  String get response_saveResponse;

  /// No description provided for @response_noResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'No response'**
  String get response_noResponseTitle;

  /// No description provided for @response_noHeadersTitle.
  ///
  /// In en, this message translates to:
  /// **'No headers'**
  String get response_noHeadersTitle;

  /// No description provided for @response_noHeadersHint.
  ///
  /// In en, this message translates to:
  /// **'Send a request to see response headers'**
  String get response_noHeadersHint;

  /// No description provided for @response_headerNameColumn.
  ///
  /// In en, this message translates to:
  /// **'Header Name'**
  String get response_headerNameColumn;

  /// No description provided for @response_cookiesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Cookie management coming soon'**
  String get response_cookiesComingSoon;

  /// No description provided for @response_noRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'No Request'**
  String get response_noRequestTitle;

  /// No description provided for @response_noRequestHint.
  ///
  /// In en, this message translates to:
  /// **'Create a request to see details'**
  String get response_noRequestHint;

  /// No description provided for @response_headersCount.
  ///
  /// In en, this message translates to:
  /// **'Headers ({count})'**
  String response_headersCount(Object count);

  /// No description provided for @response_bodyWithType.
  ///
  /// In en, this message translates to:
  /// **'Body ({type})'**
  String response_bodyWithType(Object type);

  /// No description provided for @response_urlScheme.
  ///
  /// In en, this message translates to:
  /// **'Scheme'**
  String get response_urlScheme;

  /// No description provided for @response_urlHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get response_urlHost;

  /// No description provided for @response_urlPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get response_urlPort;

  /// No description provided for @response_urlPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get response_urlPath;

  /// No description provided for @response_customCount.
  ///
  /// In en, this message translates to:
  /// **'{count} custom'**
  String response_customCount(Object count);

  /// No description provided for @response_autoAddedHeaders.
  ///
  /// In en, this message translates to:
  /// **'Auto-added Headers'**
  String get response_autoAddedHeaders;

  /// No description provided for @response_autoBadge.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get response_autoBadge;

  /// No description provided for @response_totalRequestTime.
  ///
  /// In en, this message translates to:
  /// **'Total Request Time'**
  String get response_totalRequestTime;

  /// No description provided for @response_phaseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Phase Breakdown'**
  String get response_phaseBreakdown;

  /// No description provided for @response_dnsLookup.
  ///
  /// In en, this message translates to:
  /// **'DNS Lookup'**
  String get response_dnsLookup;

  /// No description provided for @response_tcpConnect.
  ///
  /// In en, this message translates to:
  /// **'TCP Connect'**
  String get response_tcpConnect;

  /// No description provided for @response_tlsHandshake.
  ///
  /// In en, this message translates to:
  /// **'TLS Handshake'**
  String get response_tlsHandshake;

  /// No description provided for @response_ttfb.
  ///
  /// In en, this message translates to:
  /// **'TTFB (Time to First Byte)'**
  String get response_ttfb;

  /// No description provided for @response_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get response_download;

  /// No description provided for @response_timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get response_timeline;

  /// No description provided for @response_assertionsPassed.
  ///
  /// In en, this message translates to:
  /// **'{passed}/{total} passed'**
  String response_assertionsPassed(Object passed, Object total);

  /// No description provided for @response_tabRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get response_tabRequest;

  /// No description provided for @response_tabTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get response_tabTests;

  /// No description provided for @response_tabTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get response_tabTiming;

  /// No description provided for @response_tabCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get response_tabCertificate;

  /// No description provided for @response_noAssertionsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No assertions configured — add them in the Assertions tab.'**
  String get response_noAssertionsConfigured;

  /// No description provided for @response_assertionsNotRun.
  ///
  /// In en, this message translates to:
  /// **'Not run yet — send the request to evaluate assertions.'**
  String get response_assertionsNotRun;

  /// No description provided for @response_assertionDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get response_assertionDisabled;

  /// No description provided for @response_expectedValueAt.
  ///
  /// In en, this message translates to:
  /// **'value at {arg}'**
  String response_expectedValueAt(Object arg);

  /// No description provided for @response_expectedHeader.
  ///
  /// In en, this message translates to:
  /// **'header \"{arg}\"'**
  String response_expectedHeader(Object arg);

  /// No description provided for @response_expectedPresent.
  ///
  /// In en, this message translates to:
  /// **'present'**
  String get response_expectedPresent;

  /// No description provided for @response_expectedLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED'**
  String get response_expectedLabel;

  /// No description provided for @response_actualLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTUAL'**
  String get response_actualLabel;

  /// No description provided for @response_resolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get response_resolvedLabel;

  /// No description provided for @response_certValid.
  ///
  /// In en, this message translates to:
  /// **'Certificate is valid'**
  String get response_certValid;

  /// No description provided for @response_certExpired.
  ///
  /// In en, this message translates to:
  /// **'Certificate expired'**
  String get response_certExpired;

  /// No description provided for @response_certDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String response_certDaysRemaining(Object days);

  /// No description provided for @response_certExpiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired on {date}'**
  String response_certExpiredOn(Object date);

  /// No description provided for @response_certDetails.
  ///
  /// In en, this message translates to:
  /// **'Certificate Details'**
  String get response_certDetails;

  /// No description provided for @response_certSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get response_certSubject;

  /// No description provided for @response_certIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get response_certIssuer;

  /// No description provided for @response_certValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get response_certValidFrom;

  /// No description provided for @response_certValidTo.
  ///
  /// In en, this message translates to:
  /// **'Valid To'**
  String get response_certValidTo;

  /// No description provided for @response_certSignatureAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Signature Algorithm'**
  String get response_certSignatureAlgorithm;

  /// No description provided for @response_certSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get response_certSerialNumber;

  /// No description provided for @response_certSha256.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 Fingerprint'**
  String get response_certSha256;

  /// No description provided for @response_certPublicKeyAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Public Key Algorithm'**
  String get response_certPublicKeyAlgorithm;

  /// No description provided for @response_certPublicKeyLength.
  ///
  /// In en, this message translates to:
  /// **'Public Key Length'**
  String get response_certPublicKeyLength;

  /// No description provided for @response_certSan.
  ///
  /// In en, this message translates to:
  /// **'Subject Alternative Names'**
  String get response_certSan;

  /// No description provided for @response_certBits.
  ///
  /// In en, this message translates to:
  /// **'{bits} bits'**
  String response_certBits(Object bits);

  /// No description provided for @response_certChain.
  ///
  /// In en, this message translates to:
  /// **'Certificate Chain'**
  String get response_certChain;

  /// No description provided for @response_certIssuedBy.
  ///
  /// In en, this message translates to:
  /// **'Issued by: {issuer}'**
  String response_certIssuedBy(Object issuer);

  /// No description provided for @response_copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get response_copiedToClipboard;

  /// No description provided for @env_selectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select environment'**
  String get env_selectTooltip;

  /// No description provided for @env_none.
  ///
  /// In en, this message translates to:
  /// **'No Environment'**
  String get env_none;

  /// No description provided for @env_unresolvedVariables.
  ///
  /// In en, this message translates to:
  /// **'Unresolved variables: {variables}'**
  String env_unresolvedVariables(Object variables);

  /// No description provided for @env_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage Environments'**
  String get env_manage;

  /// No description provided for @env_globals.
  ///
  /// In en, this message translates to:
  /// **'Globals'**
  String get env_globals;

  /// No description provided for @env_footerHint.
  ///
  /// In en, this message translates to:
  /// **'Reference variables as {varRef} in URL, headers and body · secret values are write-only'**
  String env_footerHint(Object varRef);

  /// No description provided for @env_variableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} variables · referenced as {varRef}'**
  String env_variableCount(Object count, Object varRef);

  /// No description provided for @env_globalsHint.
  ///
  /// In en, this message translates to:
  /// **'Shared across all environments · overridden by environment variables'**
  String get env_globalsHint;

  /// No description provided for @env_sectionEnvironments.
  ///
  /// In en, this message translates to:
  /// **'ENVIRONMENTS'**
  String get env_sectionEnvironments;

  /// No description provided for @env_sectionShared.
  ///
  /// In en, this message translates to:
  /// **'SHARED'**
  String get env_sectionShared;

  /// No description provided for @env_newEnvironment.
  ///
  /// In en, this message translates to:
  /// **'New Environment'**
  String get env_newEnvironment;

  /// No description provided for @env_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get env_nameHint;

  /// No description provided for @env_deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete environment'**
  String get env_deleteTooltip;

  /// No description provided for @env_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No variables yet'**
  String get env_emptyTitle;

  /// No description provided for @env_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add one and reference it as {varRef}'**
  String env_emptySubtitle(Object varRef);

  /// No description provided for @env_addVariable.
  ///
  /// In en, this message translates to:
  /// **'Add Variable'**
  String get env_addVariable;

  /// No description provided for @env_headerKey.
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get env_headerKey;

  /// No description provided for @env_headerValue.
  ///
  /// In en, this message translates to:
  /// **'VALUE'**
  String get env_headerValue;

  /// No description provided for @env_headerType.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get env_headerType;

  /// No description provided for @env_keyHint.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get env_keyHint;

  /// No description provided for @env_valueHint.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get env_valueHint;

  /// No description provided for @env_showValue.
  ///
  /// In en, this message translates to:
  /// **'Show value'**
  String get env_showValue;

  /// No description provided for @env_hideValue.
  ///
  /// In en, this message translates to:
  /// **'Hide value'**
  String get env_hideValue;

  /// No description provided for @env_removeVariable.
  ///
  /// In en, this message translates to:
  /// **'Remove variable'**
  String get env_removeVariable;

  /// No description provided for @ai_presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get ai_presetCustom;

  /// No description provided for @ai_settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get ai_settingsTitle;

  /// No description provided for @ai_notReady.
  ///
  /// In en, this message translates to:
  /// **'Local AI is not enabled or no model is configured'**
  String get ai_notReady;

  /// No description provided for @ai_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get ai_openSettings;

  /// No description provided for @ai_enableLocal.
  ///
  /// In en, this message translates to:
  /// **'Enable Local AI'**
  String get ai_enableLocal;

  /// No description provided for @ai_providerPreset.
  ///
  /// In en, this message translates to:
  /// **'Provider Preset'**
  String get ai_providerPreset;

  /// No description provided for @ai_baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get ai_baseUrl;

  /// No description provided for @ai_model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get ai_model;

  /// No description provided for @ai_modelHint.
  ///
  /// In en, this message translates to:
  /// **'Enter manually, e.g. llama3.1:8b'**
  String get ai_modelHint;

  /// No description provided for @ai_apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get ai_apiKey;

  /// No description provided for @ai_apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty'**
  String get ai_apiKeyHint;

  /// No description provided for @ai_apiKeyNote.
  ///
  /// In en, this message translates to:
  /// **'Local models usually work without a key; only needed for Tier 2 cloud providers'**
  String get ai_apiKeyNote;

  /// No description provided for @ai_connIdle.
  ///
  /// In en, this message translates to:
  /// **'Connection not checked yet'**
  String get ai_connIdle;

  /// No description provided for @ai_connChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking connection...'**
  String get ai_connChecking;

  /// No description provided for @ai_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get ai_connected;

  /// No description provided for @ai_checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check Connection'**
  String get ai_checkConnection;

  /// No description provided for @ai_explainTitle.
  ///
  /// In en, this message translates to:
  /// **'Explain Response'**
  String get ai_explainTitle;

  /// No description provided for @ai_noResponseToExplain.
  ///
  /// In en, this message translates to:
  /// **'No response to explain'**
  String get ai_noResponseToExplain;

  /// No description provided for @ai_regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get ai_regenerate;

  /// No description provided for @ai_explaining.
  ///
  /// In en, this message translates to:
  /// **'Explaining... (local models may take 10–30 seconds)'**
  String get ai_explaining;

  /// No description provided for @ai_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ai_retry;

  /// No description provided for @ai_buildTitle.
  ///
  /// In en, this message translates to:
  /// **'Build Request with Natural Language'**
  String get ai_buildTitle;

  /// No description provided for @ai_overwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite current request?'**
  String get ai_overwriteTitle;

  /// No description provided for @ai_overwriteMessage.
  ///
  /// In en, this message translates to:
  /// **'The current request already has content. Applying the draft will overwrite its URL, Params, Headers, and Body.'**
  String get ai_overwriteMessage;

  /// No description provided for @ai_overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get ai_overwrite;

  /// No description provided for @ai_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating... (local models may take 10–30 seconds)'**
  String get ai_generating;

  /// No description provided for @ai_buildDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the request you want, e.g. POST create user with a JSON body containing name and email, requires auth'**
  String get ai_buildDescHint;

  /// No description provided for @ai_buildDraftNote.
  ///
  /// In en, this message translates to:
  /// **'The result is a draft you can keep editing after applying; field values come only from your description'**
  String get ai_buildDraftNote;

  /// No description provided for @ai_zeroRows.
  ///
  /// In en, this message translates to:
  /// **'0 rows'**
  String get ai_zeroRows;

  /// No description provided for @ai_sectionParams.
  ///
  /// In en, this message translates to:
  /// **'PARAMS'**
  String get ai_sectionParams;

  /// No description provided for @ai_sectionHeaders.
  ///
  /// In en, this message translates to:
  /// **'HEADERS'**
  String get ai_sectionHeaders;

  /// No description provided for @ai_sectionBody.
  ///
  /// In en, this message translates to:
  /// **'BODY · {type}'**
  String ai_sectionBody(Object type);

  /// No description provided for @ai_applyDraft.
  ///
  /// In en, this message translates to:
  /// **'Apply to Current Request'**
  String get ai_applyDraft;

  /// No description provided for @ai_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get ai_generate;

  /// No description provided for @ai_generateButton.
  ///
  /// In en, this message translates to:
  /// **'AI Generate'**
  String get ai_generateButton;

  /// No description provided for @ai_needResponseSample.
  ///
  /// In en, this message translates to:
  /// **'Run tests or send a request first'**
  String get ai_needResponseSample;

  /// No description provided for @ai_genAssertionsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Generate Assertions'**
  String get ai_genAssertionsTitle;

  /// No description provided for @ai_genSelected.
  ///
  /// In en, this message translates to:
  /// **'Generated from the latest response · {checked}/{total} selected'**
  String ai_genSelected(Object checked, Object total);

  /// No description provided for @ai_genDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Discarded {count} invalid suggestions'**
  String ai_genDiscarded(Object count);

  /// No description provided for @ai_addChecked.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String ai_addChecked(Object count);

  /// No description provided for @ai_generatingAssertions.
  ///
  /// In en, this message translates to:
  /// **'Generating assertions... (local models may take 10–30 seconds)'**
  String get ai_generatingAssertions;

  /// No description provided for @ai_noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No usable assertion suggestions were generated'**
  String get ai_noSuggestions;

  /// No description provided for @ai_colTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get ai_colTarget;

  /// No description provided for @ai_colPath.
  ///
  /// In en, this message translates to:
  /// **'PATH'**
  String get ai_colPath;

  /// No description provided for @ai_colOperator.
  ///
  /// In en, this message translates to:
  /// **'OPERATOR'**
  String get ai_colOperator;

  /// No description provided for @ai_colExpected.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED'**
  String get ai_colExpected;

  /// No description provided for @ai_headerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Header name'**
  String get ai_headerNameHint;

  /// No description provided for @ai_expectedValueHint.
  ///
  /// In en, this message translates to:
  /// **'Expected value'**
  String get ai_expectedValueHint;

  /// No description provided for @main_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get main_emptyTitle;

  /// No description provided for @main_emptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get started by creating your first request'**
  String get main_emptySubtitle;

  /// No description provided for @main_createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get main_createRequest;

  /// No description provided for @main_emptyShortcutHint.
  ///
  /// In en, this message translates to:
  /// **'or press Cmd+N'**
  String get main_emptyShortcutHint;

  /// No description provided for @main_selectTab.
  ///
  /// In en, this message translates to:
  /// **'Select a tab to start'**
  String get main_selectTab;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @about_tagline.
  ///
  /// In en, this message translates to:
  /// **'Hop to your APIs'**
  String get about_tagline;

  /// No description provided for @about_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get about_version;

  /// No description provided for @about_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get about_description;

  /// No description provided for @about_descriptionContent.
  ///
  /// In en, this message translates to:
  /// **'A lightweight, cross-platform API testing tool built with Flutter. Hopp makes API testing simple, fast, and enjoyable.'**
  String get about_descriptionContent;

  /// No description provided for @about_features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get about_features;

  /// No description provided for @about_featureLightweight.
  ///
  /// In en, this message translates to:
  /// **'🔥 Lightweight & Fast'**
  String get about_featureLightweight;

  /// No description provided for @about_featureCrossPlatform.
  ///
  /// In en, this message translates to:
  /// **'💻 Cross-Platform (macOS, Windows, Linux)'**
  String get about_featureCrossPlatform;

  /// No description provided for @about_featureHttp.
  ///
  /// In en, this message translates to:
  /// **'📝 Full HTTP Request Support'**
  String get about_featureHttp;

  /// No description provided for @about_featureCollections.
  ///
  /// In en, this message translates to:
  /// **'📦 Collection Management'**
  String get about_featureCollections;

  /// No description provided for @about_featureTabs.
  ///
  /// In en, this message translates to:
  /// **'📑 Multiple Tabs'**
  String get about_featureTabs;

  /// No description provided for @about_featureDarkMode.
  ///
  /// In en, this message translates to:
  /// **'🌓 Dark Mode Support'**
  String get about_featureDarkMode;

  /// No description provided for @about_featureLanguages.
  ///
  /// In en, this message translates to:
  /// **'🌍 Multi-language Support'**
  String get about_featureLanguages;

  /// No description provided for @about_featureLocal.
  ///
  /// In en, this message translates to:
  /// **'🔒 Local Data Storage'**
  String get about_featureLocal;

  /// No description provided for @about_techStack.
  ///
  /// In en, this message translates to:
  /// **'Tech Stack'**
  String get about_techStack;

  /// No description provided for @about_links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get about_links;

  /// No description provided for @about_githubRepo.
  ///
  /// In en, this message translates to:
  /// **'GitHub Repository'**
  String get about_githubRepo;

  /// No description provided for @about_reportIssues.
  ///
  /// In en, this message translates to:
  /// **'Report Issues'**
  String get about_reportIssues;

  /// No description provided for @about_reportIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit bug reports and feature requests'**
  String get about_reportIssuesSubtitle;

  /// No description provided for @about_contribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get about_contribute;

  /// No description provided for @about_contributeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help make Hopp better'**
  String get about_contributeSubtitle;

  /// No description provided for @about_builtWith.
  ///
  /// In en, this message translates to:
  /// **'Built with passion by the Hopp team'**
  String get about_builtWith;

  /// No description provided for @about_copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Hopp. All rights reserved.'**
  String get about_copyright;

  /// No description provided for @about_poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by AI · Built with Flutter'**
  String get about_poweredBy;

  /// No description provided for @gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Design Gallery'**
  String get gallery_title;

  /// No description provided for @gallery_themeTitle.
  ///
  /// In en, this message translates to:
  /// **'{theme} Theme'**
  String gallery_themeTitle(Object theme);

  /// No description provided for @gallery_colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get gallery_colors;

  /// No description provided for @gallery_groupThemeData.
  ///
  /// In en, this message translates to:
  /// **'AppThemeData (theme-dependent)'**
  String get gallery_groupThemeData;

  /// No description provided for @gallery_groupAppColors.
  ///
  /// In en, this message translates to:
  /// **'AppColors (constant palette)'**
  String get gallery_groupAppColors;

  /// No description provided for @gallery_groupSyntaxColors.
  ///
  /// In en, this message translates to:
  /// **'AppSyntaxColors (current theme)'**
  String get gallery_groupSyntaxColors;

  /// No description provided for @gallery_typography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get gallery_typography;

  /// No description provided for @gallery_pangram.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox 敏捷的狐狸'**
  String get gallery_pangram;

  /// No description provided for @gallery_metrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get gallery_metrics;

  /// No description provided for @gallery_spacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get gallery_spacing;

  /// No description provided for @gallery_radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get gallery_radius;

  /// No description provided for @gallery_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get gallery_height;

  /// No description provided for @gallery_shadows.
  ///
  /// In en, this message translates to:
  /// **'Shadows'**
  String get gallery_shadows;

  /// No description provided for @gallery_shadowNone.
  ///
  /// In en, this message translates to:
  /// **'none (border only)'**
  String get gallery_shadowNone;

  /// No description provided for @gallery_components.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get gallery_components;

  /// No description provided for @gallery_btnPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get gallery_btnPrimary;

  /// No description provided for @gallery_btnSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get gallery_btnSecondary;

  /// No description provided for @gallery_btnGhost.
  ///
  /// In en, this message translates to:
  /// **'Ghost'**
  String get gallery_btnGhost;

  /// No description provided for @gallery_btnDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get gallery_btnDanger;

  /// No description provided for @gallery_btnWithIcon.
  ///
  /// In en, this message translates to:
  /// **'With Icon'**
  String get gallery_btnWithIcon;

  /// No description provided for @gallery_btnSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get gallery_btnSmall;

  /// No description provided for @gallery_btnDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get gallery_btnDisabled;

  /// No description provided for @gallery_tipDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get gallery_tipDefault;

  /// No description provided for @gallery_tipBordered.
  ///
  /// In en, this message translates to:
  /// **'Bordered'**
  String get gallery_tipBordered;

  /// No description provided for @gallery_textFieldStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (height 32)'**
  String get gallery_textFieldStandard;

  /// No description provided for @gallery_textFieldCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact (height 28)'**
  String get gallery_textFieldCompact;

  /// No description provided for @gallery_hintSearch.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get gallery_hintSearch;

  /// No description provided for @gallery_textFieldMultiline.
  ///
  /// In en, this message translates to:
  /// **'Multiline (maxLines: 3)'**
  String get gallery_textFieldMultiline;

  /// No description provided for @gallery_hintBody.
  ///
  /// In en, this message translates to:
  /// **'Body…'**
  String get gallery_hintBody;

  /// No description provided for @gallery_switchOn.
  ///
  /// In en, this message translates to:
  /// **'switch on'**
  String get gallery_switchOn;

  /// No description provided for @gallery_switchOff.
  ///
  /// In en, this message translates to:
  /// **'switch off'**
  String get gallery_switchOff;

  /// No description provided for @gallery_checked.
  ///
  /// In en, this message translates to:
  /// **'checked'**
  String get gallery_checked;

  /// No description provided for @gallery_unchecked.
  ///
  /// In en, this message translates to:
  /// **'unchecked'**
  String get gallery_unchecked;

  /// No description provided for @gallery_cardStandard.
  ///
  /// In en, this message translates to:
  /// **'standard: surface background + border'**
  String get gallery_cardStandard;

  /// No description provided for @gallery_cardElevated.
  ///
  /// In en, this message translates to:
  /// **'elevated: background + shadowMd'**
  String get gallery_cardElevated;

  /// No description provided for @gallery_selectEnvHint.
  ///
  /// In en, this message translates to:
  /// **'Select env'**
  String get gallery_selectEnvHint;

  /// No description provided for @gallery_emptyDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a request to get started'**
  String get gallery_emptyDemoSubtitle;

  /// No description provided for @ai_callFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'AI call failed'**
  String get ai_callFailedGeneric;

  /// No description provided for @http_requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout: {message}'**
  String http_requestTimeout(Object message);

  /// No description provided for @http_serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error: {code} {message}'**
  String http_serverError(Object code, Object message);

  /// No description provided for @http_requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get http_requestCancelled;

  /// No description provided for @http_connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {message}'**
  String http_connectionError(Object message);

  /// No description provided for @http_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {message}'**
  String http_networkError(Object message);

  /// No description provided for @http_unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {message}'**
  String http_unexpectedError(Object message);

  /// No description provided for @http_certErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'SSL Certificate Error'**
  String get http_certErrorTitle;

  /// No description provided for @http_certSelfSigned.
  ///
  /// In en, this message translates to:
  /// **'The server is using a self-signed certificate.'**
  String get http_certSelfSigned;

  /// No description provided for @http_certExpired.
  ///
  /// In en, this message translates to:
  /// **'The server\'s SSL certificate has expired.'**
  String get http_certExpired;

  /// No description provided for @http_certHostnameMismatch.
  ///
  /// In en, this message translates to:
  /// **'The server\'s SSL certificate does not match the hostname.'**
  String get http_certHostnameMismatch;

  /// No description provided for @http_certUntrusted.
  ///
  /// In en, this message translates to:
  /// **'The server\'s SSL certificate is not trusted.'**
  String get http_certUntrusted;

  /// No description provided for @http_certVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify the server\'s SSL certificate.'**
  String get http_certVerifyFailed;

  /// No description provided for @http_certTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details: {message}'**
  String http_certTechnicalDetails(Object message);

  /// No description provided for @http_certTipDisable.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip: You can disable \"Enable SSL certificate verification\" in Settings > SSL/TLS to bypass this error for testing purposes.'**
  String get http_certTipDisable;

  /// No description provided for @http_certAlreadyDisabled.
  ///
  /// In en, this message translates to:
  /// **'💡 SSL verification is already disabled, but the connection still failed.'**
  String get http_certAlreadyDisabled;

  /// No description provided for @http_cancelledByUser.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by user'**
  String get http_cancelledByUser;

  /// No description provided for @prereq_referencedMissing.
  ///
  /// In en, this message translates to:
  /// **'Referenced request not found ({id}); it may have been deleted'**
  String prereq_referencedMissing(Object id);

  /// No description provided for @assertion_operatorNotSupported.
  ///
  /// In en, this message translates to:
  /// **'operator {operator} is not supported for target {target}'**
  String assertion_operatorNotSupported(Object operator, Object target);

  /// No description provided for @assertion_noResponse.
  ///
  /// In en, this message translates to:
  /// **'no response'**
  String get assertion_noResponse;

  /// No description provided for @assertion_expectedNotANumber.
  ///
  /// In en, this message translates to:
  /// **'expected not a number'**
  String get assertion_expectedNotANumber;

  /// No description provided for @assertion_expectedComparison.
  ///
  /// In en, this message translates to:
  /// **'expected {operator} {expected}'**
  String assertion_expectedComparison(Object expected, Object operator);

  /// No description provided for @assertion_headerNotFound.
  ///
  /// In en, this message translates to:
  /// **'header not found'**
  String get assertion_headerNotFound;

  /// No description provided for @assertion_headerExists.
  ///
  /// In en, this message translates to:
  /// **'header exists'**
  String get assertion_headerExists;

  /// No description provided for @assertion_expectedEquals.
  ///
  /// In en, this message translates to:
  /// **'expected \"{expected}\"'**
  String assertion_expectedEquals(Object expected);

  /// No description provided for @assertion_expectedNotEquals.
  ///
  /// In en, this message translates to:
  /// **'expected not \"{expected}\"'**
  String assertion_expectedNotEquals(Object expected);

  /// No description provided for @assertion_expectedContain.
  ///
  /// In en, this message translates to:
  /// **'expected to contain \"{expected}\"'**
  String assertion_expectedContain(Object expected);

  /// No description provided for @assertion_expectedNotContain.
  ///
  /// In en, this message translates to:
  /// **'expected not to contain \"{expected}\"'**
  String assertion_expectedNotContain(Object expected);

  /// No description provided for @assertion_invalidRegex.
  ///
  /// In en, this message translates to:
  /// **'invalid regex'**
  String get assertion_invalidRegex;

  /// No description provided for @assertion_expectedMatch.
  ///
  /// In en, this message translates to:
  /// **'expected to match /{expected}/'**
  String assertion_expectedMatch(Object expected);

  /// No description provided for @assertion_expectedBodyContain.
  ///
  /// In en, this message translates to:
  /// **'expected body to contain \"{expected}\"'**
  String assertion_expectedBodyContain(Object expected);

  /// No description provided for @assertion_expectedBodyNotContain.
  ///
  /// In en, this message translates to:
  /// **'expected body not to contain \"{expected}\"'**
  String assertion_expectedBodyNotContain(Object expected);

  /// No description provided for @assertion_expectedBodyEqual.
  ///
  /// In en, this message translates to:
  /// **'expected body to equal \"{expected}\"'**
  String assertion_expectedBodyEqual(Object expected);

  /// No description provided for @assertion_expectedBodyNotEqual.
  ///
  /// In en, this message translates to:
  /// **'expected body not to equal \"{expected}\"'**
  String assertion_expectedBodyNotEqual(Object expected);

  /// No description provided for @assertion_expectedBodyMatch.
  ///
  /// In en, this message translates to:
  /// **'expected body to match /{expected}/'**
  String assertion_expectedBodyMatch(Object expected);

  /// No description provided for @assertion_bodyNotJson.
  ///
  /// In en, this message translates to:
  /// **'response body is not valid JSON'**
  String get assertion_bodyNotJson;

  /// No description provided for @assertion_invalidJsonPath.
  ///
  /// In en, this message translates to:
  /// **'invalid JSONPath expression'**
  String get assertion_invalidJsonPath;

  /// No description provided for @assertion_pathNotFound.
  ///
  /// In en, this message translates to:
  /// **'path not found'**
  String get assertion_pathNotFound;

  /// No description provided for @assertion_pathExists.
  ///
  /// In en, this message translates to:
  /// **'path exists'**
  String get assertion_pathExists;

  /// No description provided for @assertion_valueNotANumber.
  ///
  /// In en, this message translates to:
  /// **'value is not a number'**
  String get assertion_valueNotANumber;

  /// No description provided for @assertion_noTimingInfo.
  ///
  /// In en, this message translates to:
  /// **'no timing info'**
  String get assertion_noTimingInfo;

  /// No description provided for @var_dynamicDescTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Current Unix timestamp (seconds)'**
  String get var_dynamicDescTimestamp;

  /// No description provided for @var_dynamicDescTimestampMs.
  ///
  /// In en, this message translates to:
  /// **'Current Unix timestamp (milliseconds)'**
  String get var_dynamicDescTimestampMs;

  /// No description provided for @var_dynamicDescIsoTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Current UTC ISO8601 time'**
  String get var_dynamicDescIsoTimestamp;

  /// No description provided for @var_dynamicDescRandomUuid.
  ///
  /// In en, this message translates to:
  /// **'Random UUID v4'**
  String get var_dynamicDescRandomUuid;

  /// No description provided for @var_dynamicDescRandomInt.
  ///
  /// In en, this message translates to:
  /// **'Random integer between 0 and 1000000'**
  String get var_dynamicDescRandomInt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
