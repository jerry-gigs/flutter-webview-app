import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionCheckService {
  // GitHUB Version check PATH
  static const String versionCheckUrl = 
      'https://jerry-gigs.github.io/app-version-control/version_check.json';
  
  // App version info
  String? _currentAppVersion;
  
  // Remote config
  String? _minRequiredVersion;
  String? _currentRemoteVersion;
  bool? _forceUpdate;
  String? _updateUrl;
  String? _message;
  String? _title;
  String? _error;
  
  Future<void> initialize() async {
    await _loadAppVersion();
    await _loadRemoteVersionConfig();
  }
  
  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentAppVersion = packageInfo.version;
  }
  
  Future<void> _loadRemoteVersionConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$versionCheckUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        }
      );
      
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        
        _minRequiredVersion = config['min_required_version'];
        _currentRemoteVersion = config['current_version'];
        _forceUpdate = config['force_update'] ?? false;
        _updateUrl = config['update_url'];
        _message = config['message'];
        _title = config['title'];
        _error = null;
      } else {
        _error = 'Failed to load version config: ${response.statusCode}';
        _setDefaultValues();
      }
    } catch (e) {
      _error = 'Error loading version config: $e';
      _setDefaultValues();
    }
  }
  
  void _setDefaultValues() {
    // Safe defaults - require update if we can't reach server
    _forceUpdate = true;
    _message = 'Unable to check for updates. Please check your connection.';
    _title = 'Update Check Failed';
  }
  
  bool get isUpdateRequired {
    if (_currentAppVersion == null || _minRequiredVersion == null) {
      return true; // Be safe, require update if we can't determine version
    }
    
    return _compareVersions(_currentAppVersion!, _minRequiredVersion!) < 0;
  }
  
  int _compareVersions(String version1, String version2) {
    try {
      // Handle version format like "1.0.1+1" by splitting on '+'
      String cleanV1 = version1.split('+').first;
      String cleanV2 = version2.split('+').first;
      
      final v1 = cleanV1.split('.').map(int.parse).toList();
      final v2 = cleanV2.split('.').map(int.parse).toList();
      
      for (int i = 0; i < v1.length; i++) {
        if (v2.length <= i) return 1;
        if (v1[i] > v2[i]) return 1;
        if (v1[i] < v2[i]) return -1;
      }
      
      if (v2.length > v1.length) return -1;
      return 0;
    } catch (e) {
      return -1; // Treat parse errors as needing update
    }
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
      'error': _error,
      'update_required': isUpdateRequired && (_forceUpdate ?? false),
    };
  }
  
  // Helper method to check if everything loaded successfully
  bool get isInitialized => _currentAppVersion != null && _error == null;
}