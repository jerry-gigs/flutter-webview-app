import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import 'package:shared_preferences/shared_preferences.dart';

class WebViewService {
  dynamic controller; // Controller for either Windows or mobile WebView
  bool _isWindows = false;

  WebViewService() {
    _isWindows = _checkIfWindows();
    if (_isWindows) {
      controller = windows_webview.WebviewController();
    } else {
      controller = mobile_webview.WebViewController();
    }
  }

  bool _checkIfWindows() {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  bool get isWindows => _isWindows;

  // Initialize WebView (persistent cookies by default)
  Future<void> initialize() async {
    if (_isWindows) {
      try {
        final windowsController = controller as windows_webview.WebviewController;
        await windowsController.initialize();
        // Persistent session handled automatically by WebView
      } catch (e) {
        print('Windows WebView initialization failed: $e');
        _isWindows = false;
        controller = mobile_webview.WebViewController();
      }
    }
    // Mobile WebView persists cookies/local storage by default
  }

  // Load URL
  Future<void> loadUrl(String url) async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).loadUrl(url);
    } else {
      await (controller as mobile_webview.WebViewController)
          .loadRequest(Uri.parse(url));
    }
  }

  Future<void> goBack() async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).goBack();
    } else {
      final canGoBack =
          await (controller as mobile_webview.WebViewController).canGoBack();
      if (canGoBack) {
        await (controller as mobile_webview.WebViewController).goBack();
      }
    }
  }

  Future<void> goForward() async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).goForward();
    } else {
      final canGoForward =
          await (controller as mobile_webview.WebViewController).canGoForward();
      if (canGoForward) {
        await (controller as mobile_webview.WebViewController).goForward();
      }
    }
  }

  Future<void> reload() async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).reload();
    } else {
      await (controller as mobile_webview.WebViewController).reload();
    }
  }

  // ===============================
  // Do NOT clear cookies automatically
  // ===============================
  Future<void> clearCookies() async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).clearCookies();
    } else {
      // Only clear if user explicitly wants to
      await (controller as mobile_webview.WebViewController).clearLocalStorage();
    }
  }

  Future<void> clearCache() async {
    if (!_isWindows) {
      await (controller as mobile_webview.WebViewController).clearCache();
    }
  }

  Future<void> setUserAgent(String userAgent) async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController)
          .setUserAgent(userAgent);
    } else {
      await (controller as mobile_webview.WebViewController)
          .setUserAgent(userAgent);
    }
  }

  // ===============================
  // REMEMBER LOGIN FUNCTIONALITY
  // ===============================

  // Save "remember login" flag for mobile
  static Future<void> saveRememberLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_login', value);
  }

  // Retrieve "remember login" flag for mobile
  static Future<bool> getRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_login') ?? false;
  }

  // Inject JavaScript to auto-check "Remember Me" if needed
  Future<void> enableRememberMePopup() async {
    const jsScript =
        'const remember = document.querySelector("#rememberMe");'
        'if(remember){remember.checked = true;}';
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).executeScript(jsScript);
    } else {
      await (controller as mobile_webview.WebViewController).runJavaScript(jsScript);
    }
  }
}
