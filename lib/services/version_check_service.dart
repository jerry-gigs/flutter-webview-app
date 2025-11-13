import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  static const String versionConfigPath = 'assets/version_check.json';
  
  // App version info
  String? _currentAppVersion;
  
  // Remote config
  String? _minRequiredVersion;
  String? _currentRemoteVersion;
  bool? _forceUpdate;
  String? _updateUrl;
  String? _message;
  String? _title;
  
  Future<void> initialize() async {
    await _loadAppVersion();
    await _loadVersionConfig();
  }
  
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentAppVersion = packageInfo.version;
  }
  
  Future<void> _loadVersionConfig() async {
    try {
      final jsonString = await rootBundle.loadString(versionConfigPath);
      final config = json.decode(jsonString);
      
      _minRequiredVersion = config['min_required_version'];
      _currentRemoteVersion = config['current_version'];
      _forceUpdate = config['force_update'] ?? false;
      _updateUrl = config['update_url'];
      _message = config['message'];
      _title = config['title'];
    } catch (e) {
      print('Error loading version config: $e');
      // Set default values if config fails to load
      _forceUpdate = true;
      _message = 'Update required to continue';
      _title = 'Update Required';
    }
  }
  
  bool get isUpdateRequired {
    if (_currentAppVersion == null || _minRequiredVersion == null) {
      return true; // Be safe, require update if we can't determine version
    }
    
    return _compareVersions(_currentAppVersion!, _minRequiredVersion!) < 0;
  }
  
  int _compareVersions(String version1, String version2) {
    final v1 = version1.split('.').map(int.parse).toList();
    final v2 = version2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < v1.length; i++) {
      if (v2.length <= i) return 1;
      if (v1[i] > v2[i]) return 1;
      if (v1[i] < v2[i]) return -1;
    }
    
    if (v2.length > v1.length) return -1;
    return 0;
  }
  
  Map<String, dynamic> get updateInfo {
    return {
      'force_update': _forceUpdate,
      'update_url': _updateUrl,
      'message': _message,
      'title': _title,
      'current_app_version': _currentAppVersion,
      'min_required_version': _minRequiredVersion,
      'current_remote_version': _currentRemoteVersion,
    };
  }
}