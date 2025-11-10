import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;

class WebViewService {
  dynamic controller;
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
    // More reliable platform detection
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  bool get isWindows => _isWindows;

  Future<void> initialize() async {
    if (_isWindows) {
      try {
        await (controller as windows_webview.WebviewController).initialize();
      } catch (e) {
        print('Windows WebView initialization failed: $e');
        // Fallback to mobile webview if Windows initialization fails
        _isWindows = false;
        controller = mobile_webview.WebViewController();
      }
    }
    // Mobile webview doesn't need explicit initialization
  }

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
      final canGoBack = await (controller as mobile_webview.WebViewController)
          .canGoBack();
      if (canGoBack) {
        await (controller as mobile_webview.WebViewController).goBack();
      }
    }
  }

  Future<void> goForward() async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).goForward();
    } else {
      final canGoForward = await (controller as mobile_webview.WebViewController)
          .canGoForward();
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

  Future<void> clearCookies() async {
    if (_isWindows) {
      await (controller as windows_webview.WebviewController).clearCookies();
    } else {
      // For mobile, clear local storage
      await (controller as mobile_webview.WebViewController).clearLocalStorage();
    }
  }

  Future<void> clearCache() async {
    if (!_isWindows) {
      await (controller as mobile_webview.WebViewController).clearCache();
    }
    // Windows cache clearing is handled in clearCookies()
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
}