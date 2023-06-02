/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/Storage.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/utils/crypt.dart';
import 'package:universal_html/html.dart' as html;

class Config with Service, NetworkAuthProvider, NotificationsListener {

  static const String notifyUpgradeRequired     = "edu.illinois.rokwire.config.upgrade.required";
  static const String notifyUpgradeAvailable    = "edu.illinois.rokwire.config.upgrade.available";
  static const String notifyOnboardingRequired  = "edu.illinois.rokwire.config.onboarding.required";
  static const String notifyConfigChanged       = "edu.illinois.rokwire.config.changed";
  static const String notifyEnvironmentChanged  = "edu.illinois.rokwire.config.environment.changed";

  static const String _configsAsset       = "configs.json.enc";
  static const String _configKeysAsset    = "config.keys.json";

  static const String _rokwireApiKey       = 'ROKWIRE-API-KEY';

  Map<String, dynamic>? _config;
  Map<String, dynamic>? _configAsset;
  Map<String, dynamic>? _encryptionKeys;
  ConfigEnvironment?    _configEnvironment;
  PackageInfo?          _packageInfo;
  Directory?            _appDocumentsDir; 
  String?               _appCanonicalId;
  String?               _appPlatformId;
  DateTime?             _pausedDateTime;
  
  final Set<String>        _reportedUpgradeVersions = <String>{};
  final ConfigEnvironment? _defaultConfigEnvironment;

  // Singletone Factory

  static Config? _instance;

  static Config? get instance => _instance;
  
  @protected
  static set instance(Config? value) => _instance = value;

  factory Config({ConfigEnvironment? defaultEnvironment}) => _instance ?? (_instance = Config.internal(defaultEnvironment: defaultEnvironment));

  @protected
  Config.internal({ConfigEnvironment? defaultEnvironment}) :
    _defaultConfigEnvironment = defaultEnvironment;

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLifecycle.notifyStateChanged,
      //TBD: FirebaseMessaging.notifyConfigUpdate
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {

    _configEnvironment = configEnvFromString(Storage().configEnvironment) ?? _defaultConfigEnvironment ?? defaultConfigEnvironment;

    _packageInfo = await PackageInfo.fromPlatform();
    if (!kIsWeb) {
      _appDocumentsDir = await getApplicationDocumentsDirectory();
      Log.d('Application Documents Directory: ${_appDocumentsDir!.path}');
    }

    await init();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { Storage(), Connectivity() };
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
    //else if (name == FirebaseMessaging.notifyConfigUpdate) {
    //  updateFromNet();
    //}
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (refreshTimeout < pausedDuration.inSeconds) {
          updateFromNet();
        }
      }
    }
  }

  // NetworkAuthProvider

  @override
  Map<String, String>? get networkAuthHeaders {
    String? value = rokwireApiKey;
    if ((value != null) && value.isNotEmpty) {
      return { _rokwireApiKey : value };
    }
    return null;
  }

  // Implementation

  @protected
  String get configName {
    String? configTarget = configEnvToString(_configEnvironment);
    return "config.$configTarget.json";
  }

  @protected
  File get configFile {
    String configFilePath = join(_appDocumentsDir!.path, configName);
    return File(configFilePath);
  }

  @protected
  Future<Map<String, dynamic>?> loadFromFile(File? configFile) async {
    try {
      String? configContent = (await configFile?.exists() == true) ? await configFile?.readAsString() : null;
      return configFromJsonString(configContent);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @protected
  String get configsAsset => _configsAsset;

  @protected
  Future<Map<String, dynamic>?> loadFromAssets() async {
    try {
      String configsStrEnc = await rootBundle.loadString('assets/$configsAsset');
      String? configsStr = AESCrypt.decrypt(configsStrEnc, key: encryptionKey, iv: encryptionIV);
      Map<String, dynamic>? configs = JsonUtils.decode(configsStr);
      String? configTarget = configEnvToString(_configEnvironment);
      return (configs != null) ? configs[configTarget] : null;
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  @protected
  Future<String?> loadAsStringFromNet() async {
    return loadAsStringFromCore();
  }

  Future<String?> loadAsStringFromAppConfig() async {
    try {
      http.Response? response = await Network().get(appConfigUrl, auth: this);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<String?> loadAsStringFromCore() async {
    Map<String, dynamic> body = {
      'version': appVersion,
      'app_type_identifier': appPlatformId,
      'api_key': rokwireApiKey,
    };
    String? bodyString =  JsonUtils.encode(body);
    try {
      http.Response? response = await Network().post(appConfigUrl, body: bodyString, headers: {'content-type': 'application/json'});
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @protected
  Map<String, dynamic>? configFromJsonString(String? configJsonString) {
    return configFromJsonObjectString(configJsonString);
  }

  @protected
  Map<String, dynamic>? configFromJsonObjectString(String? configJsonString) {
    Map<String, dynamic>? configJson = JsonUtils.decode(configJsonString);
    Map<String, dynamic>? configData = configJson?["data"];
    if (configData != null) {
      decryptSecretKeys(configData);
      return configData;
    }
    return null;
  }

  @protected
  Map<String, dynamic>? configFromJsonListString(String? configJsonString) {
    dynamic configJson =  JsonUtils.decode(configJsonString);
    List<dynamic>? jsonList = (configJson is List) ? configJson : null;
    if (jsonList != null) {

      jsonList.sort((dynamic cfg1, dynamic cfg2) {
        return ((cfg1 is Map) && (cfg2 is Map)) ? AppVersion.compareVersions(cfg1['mobileAppVersion'], cfg2['mobileAppVersion']) : 0;
      });

      for (int index = jsonList.length - 1; index >= 0; index--) {
        Map<String, dynamic> cfg = jsonList[index];
        if (AppVersion.compareVersions(cfg['mobileAppVersion'], _packageInfo!.version) <= 0) {
          decryptSecretKeys(cfg);
          return cfg;
        }
      }
    }

    return null;
  }

  @protected
  void decryptSecretKeys(Map<String, dynamic>? config) {
    dynamic secretKeys = config?['secretKeys'];
    if (secretKeys is String) {
      config?['secretKeys'] = JsonUtils.decodeMap(AESCrypt.decrypt(secretKeys, key: encryptionKey, iv: encryptionIV));
    }

    if (config?['secretKeys'] is! Map<String, dynamic>) {
      // Handle different encryption keys for limiting developer secret access
      dynamic secrets = config?['secrets'];
      if (secrets is Map<String, dynamic>) {
        secretKeys = secrets[encryptionID];
        if (secretKeys is String) {
          config?['secretKeys'] = JsonUtils.decodeMap(AESCrypt.decrypt(secretKeys, key: encryptionKey, iv: encryptionIV));
        }
      }
    }
  }

  @protected

  String get configKeysAsset => _configKeysAsset;

  @protected
  Future<Map<String, dynamic>?> loadEncryptionKeysFromAssets() async {
    try {
      return JsonUtils.decode(await rootBundle.loadString('assets/$configKeysAsset'));
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  @protected
  Future<void> init() async {
    
    _encryptionKeys = await loadEncryptionKeysFromAssets();
    if (_encryptionKeys == null) {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.fatal,
        title: 'Config Initialization Failed',
        description: 'Failed to load config encryption keys.',
      );
    }

    if (!kIsWeb) {
      _config = await loadFromFile(configFile);
    }

    if (_config == null) {
      if (!isReleaseWeb) {
        _configAsset = await loadFromAssets();
      }
      String? configString = await loadAsStringFromNet();
      _configAsset = null;

      _config = (configString != null) ? configFromJsonString(configString) : null;
      if (_config != null && secretKeys.isNotEmpty) {
        configFile.writeAsStringSync(configString!, flush: true);
        checkUpgrade();
      }
      else {
        throw ServiceError(
          source: this,
          severity: ServiceErrorSeverity.fatal,
          title: 'Config Initialization Failed',
          description: 'Failed to initialize application configuration.',
        );
      }
    }
    else {
      checkUpgrade();
      updateFromNet();
    }
  }

  @protected
  void updateFromNet() {
    loadAsStringFromNet().then((String? configString) {
      Map<String, dynamic>? config = configFromJsonString(configString);
      if ((config != null) && (AppVersion.compareVersions(content['mobileAppVersion'], config['mobileAppVersion']) <= 0) && !const DeepCollectionEquality().equals(_config, config))  {
        _config = config;
        configFile.writeAsString(configString!, flush: true);
        NotificationService().notify(notifyConfigChanged, null);

        checkUpgrade();
      }
    });
  }

  // App Id & Version

  String get operatingSystem => kIsWeb ? 'web' : Platform.operatingSystem;
  String get localeName => kIsWeb ? 'unknown' : Platform.localeName;

  String? get appId {
    return _packageInfo?.packageName;
  }

  String? get appCanonicalId {
    if (_appCanonicalId == null) {
      _appCanonicalId = appId;
      
      String platformSuffix = ".${operatingSystem.toLowerCase()}";
      if ((_appCanonicalId != null) && _appCanonicalId!.endsWith(platformSuffix)) {
        _appCanonicalId = _appCanonicalId!.substring(0, _appCanonicalId!.length - platformSuffix.length);
      }
    }
    return _appCanonicalId;
  }

  String? get appPlatformId {
    if (kIsWeb) {
      return 'https://app-template-flutter.dev.api.rokmetro.com/app-template-flutter'; // '${html.window.location.origin}/$webServiceId';
    } else if (_appPlatformId == null) {
      _appPlatformId = appId;

      String platformSuffix = ".${operatingSystem.toLowerCase()}";
      if ((_appPlatformId != null) && !_appPlatformId!.endsWith(platformSuffix)) {
        _appPlatformId = _appPlatformId! + platformSuffix;
      }
    }
    return _appPlatformId;
  }

  String? get appVersion {
    return _packageInfo?.version;
  }

  String? get appMajorVersion {
    return AppVersion.majorVersion(appVersion, 2);
  }

  String? get appMasterVersion {
    return AppVersion.majorVersion(appVersion, 1);
  }

  String? get appStoreId {
    String? appStoreUrl = MapPathKey.entry(upgradeInfo, 'url.ios');
    Uri? uri = (appStoreUrl != null) ? Uri.tryParse(appStoreUrl) : null;
    return ((uri != null) && uri.pathSegments.isNotEmpty) ? uri.pathSegments.last : null;
  }

  String? get webServiceId => null;

  // Getters: Config Asset Acknowledgement

  String? get appConfigUrl {
    String? assetUrl = (_configAsset != null) ? JsonUtils.stringValue(_configAsset!['config_url'])  : null;
    return assetUrl ?? JsonUtils.stringValue(platformBuildingBlocks['appconfig_url']);
  } 
  
  String? get rokwireApiKey          {
    String? assetKey = (_configAsset != null) ? JsonUtils.stringValue(_configAsset!['api_key']) : null;
    return assetKey ?? secretRokwire['api_key'];
  }

  // Getters: Encryption Keys

  String? get encryptionID => (_encryptionKeys != null) ? _encryptionKeys!['id'] : null;
  String? get encryptionKey => (_encryptionKeys != null) ? _encryptionKeys!['key'] : null;
  String? get encryptionIV => (_encryptionKeys != null) ? _encryptionKeys!['iv'] : null;

  // Upgrade

  String? get upgradeRequiredVersion {
    dynamic requiredVersion = upgradeStringEntry('required_version');
    if ((requiredVersion is String) && (AppVersion.compareVersions(_packageInfo!.version, requiredVersion) < 0)) {
      return requiredVersion;
    }
    return null;
  }

  String? get upgradeAvailableVersion {
    dynamic availableVersion = upgradeStringEntry('available_version');
    bool upgradeAvailable = (availableVersion is String) &&
        (AppVersion.compareVersions(_packageInfo!.version, availableVersion) < 0) &&
        !Storage().reportedUpgradeVersions.contains(availableVersion) &&
        !_reportedUpgradeVersions.contains(availableVersion);
    return upgradeAvailable ? availableVersion : null;
  }

  String? get upgradeUrl {
    return upgradeStringEntry('url');
  }

  void setUpgradeAvailableVersionReported(String? version, { bool permanent = false }) {
    if (permanent) {
      Storage().reportedUpgradeVersion = version;
    }
    else if (version != null) {
      _reportedUpgradeVersions.add(version);
    }
  }

  @protected
  void checkUpgrade() {
    String? value;
    if ((value = upgradeRequiredVersion) != null) {
      NotificationService().notify(notifyUpgradeRequired, value);
    }
    else if ((value = upgradeAvailableVersion) != null) {
      NotificationService().notify(notifyUpgradeAvailable, value);
    }
  }

  String? upgradeStringEntry(String key) {
    dynamic entry = upgradeInfo[key];
    if (entry is String) {
      return entry;
    }
    else if (entry is Map) {
      dynamic value = entry[operatingSystem.toLowerCase()];
      return (value is String) ? value : null;
    }
    else {
      return null;
    }
  }

  // Environment

  set configEnvironment(ConfigEnvironment? configEnvironment) {
    if (_configEnvironment != configEnvironment) {
      _configEnvironment = configEnvironment;
      Storage().configEnvironment = configEnvToString(_configEnvironment);

      init().catchError((e){
        debugPrint(e.toString());
      }).whenComplete((){
        NotificationService().notify(notifyEnvironmentChanged, null);
      });
    }
  }

  ConfigEnvironment? get configEnvironment {
    return _configEnvironment;
  }

  ConfigEnvironment get defaultConfigEnvironment {
    return kDebugMode ? ConfigEnvironment.dev : ConfigEnvironment.production;
  }

  // Assets cache path

  Directory? get appDocumentsDir {
    return _appDocumentsDir;
  }

  Directory? get assetsCacheDir  {

    String? assetsUrl = this.assetsUrl;
    String? assetsCacheDir = _appDocumentsDir?.path;
    if ((assetsCacheDir != null) && (assetsUrl != null)) {
      try {
        Uri assetsUri = Uri.parse(assetsUrl);
        for (String pathSegment in assetsUri.pathSegments) {
          assetsCacheDir = join(assetsCacheDir!, pathSegment);
        }
      }
      on Exception catch(e) {
        debugPrint(e.toString());
      }
    }

    return (assetsCacheDir != null) ? Directory(assetsCacheDir) : null;
  }

  bool get supportsAnonymousAuth => false;

  // Getters: compound entries
  Map<String, dynamic> get content                 => _config ?? {};

  Map<String, dynamic> get secretKeys              => JsonUtils.mapValue(content['secretKeys']) ?? {};
  Map<String, dynamic> get secretRokwire           => JsonUtils.mapValue(secretKeys['rokwire']) ?? {};
  Map<String, dynamic> get secretCore              => JsonUtils.mapValue(secretKeys['core'])  ?? {};

  Map<String, dynamic> get otherUniversityServices => JsonUtils.mapValue(content['otherUniversityServices']) ?? {};
  Map<String, dynamic> get platformBuildingBlocks  => JsonUtils.mapValue(content['platformBuildingBlocks']) ?? {};
  
  Map<String, dynamic> get settings                => JsonUtils.mapValue(content['settings'])  ?? {};
  Map<String, dynamic> get upgradeInfo             => JsonUtils.mapValue(content['upgrade']) ?? {};
  
  List<dynamic>? get supportedLocales              => JsonUtils.listValue(content['languages']);

  // Getters: platformBuildingBlocks
  String? get coreUrl          => JsonUtils.stringValue(platformBuildingBlocks['core_url']);
  String? get notificationsUrl => JsonUtils.stringValue(platformBuildingBlocks["notifications_url"]);
  String? get loggingUrl       => JsonUtils.stringValue(platformBuildingBlocks['logging_url']);
  String? get quickPollsUrl    => JsonUtils.stringValue(platformBuildingBlocks["polls_url"]);
  String? get eventsUrl        => JsonUtils.stringValue(platformBuildingBlocks['events_url']);
  String? get groupsUrl        => JsonUtils.stringValue(platformBuildingBlocks["groups_url"]);
  String? get contentUrl       => JsonUtils.stringValue(platformBuildingBlocks["content_url"]);
  String? get surveysUrl       => JsonUtils.stringValue(platformBuildingBlocks["surveys_url"]);

  // Getters: otherUniversityServices
  String? get assetsUrl => JsonUtils.stringValue(otherUniversityServices['assets_url']);

  // Getters: secretKeys
  String? get coreOrgId => JsonUtils.stringValue(secretCore['org_id']);

  // Getters: settings
  int  get refreshTimeout           => JsonUtils.intValue(settings['refreshTimeout'])  ?? 0;
  int? get analyticsDeliveryTimeout => JsonUtils.intValue(settings['analyticsDeliveryTimeout']);
  int  get refreshTokenRetriesCount => JsonUtils.intValue(settings['refreshTokenRetriesCount']) ?? 3;
  String? get timezoneLocation      => JsonUtils.stringValue(settings['timezoneLocation']) ?? 'America/Chicago';

  // Getters: other
  String? get deepLinkRedirectUrl {
    Uri? assetsUri = StringUtils.isNotEmpty(assetsUrl) ? Uri.tryParse(assetsUrl!) : null;
    return (assetsUri != null) ? "${assetsUri.scheme}://${assetsUri.host}/html/redirect.html" : null;
  }

  bool get isAdmin => false;
  bool get isReleaseWeb => kIsWeb && !kDebugMode;
  bool get bypassLogin => true; // Bypass login for testing web layouts
  String? get authBaseUrl {
    if (isReleaseWeb) {
      return '${html.window.location.origin}/$webServiceId';
    } else if (isAdmin) {
      return '$coreUrl/admin';
    }
    return '$coreUrl/services';
  }
}

enum ConfigEnvironment { production, test, dev }

String? configEnvToString(ConfigEnvironment? env) {
  if (env == ConfigEnvironment.production) {
    return 'production';
  }
  else if (env == ConfigEnvironment.test) {
    return 'test';
  }
  else if (env == ConfigEnvironment.dev) {
    return 'dev';
  }
  else {
    return null;
  }
}

ConfigEnvironment? configEnvFromString(String? value) {
  if ('production' == value) {
    return ConfigEnvironment.production;
  }
  else if ('test' == value) {
    return ConfigEnvironment.test;
  }
  else if ('dev' == value) {
    return ConfigEnvironment.dev;
  }
  else {
    return null;
  }
}

