import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
import 'package:webview_windows/webview_windows.dart' as windows_webview;
import 'package:package_info_plus/package_info_plus.dart';
import 'services/webview_services.dart';
import 'services/version_check_service.dart';
import 'screens/update_required.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewService webViewService;
  final VersionCheckService versionCheckService = VersionCheckService();
  final urlController = TextEditingController();
  bool _isLoading = true;
  bool _isWindows = false;
  bool _updateCheckComplete = false;
  bool _updateRequired = false;
  Map<String, dynamic> _updateInfo = {};

  @override
  void initState() {
    super.initState();
    _isWindows = _checkIfWindows();
    webViewService = WebViewService();
    _checkForUpdates();
  }

  bool _checkIfWindows() {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  Future<void> _checkForUpdates() async {
    try {
      await versionCheckService.initialize();
      
      setState(() {
        _updateRequired = versionCheckService.isUpdateRequired;
        _updateInfo = versionCheckService.updateInfo;
        _updateCheckComplete = true;
      });
      
      if (!_updateRequired) {
        // Only initialize WebView if no update is required
        await _initWebView();
      }
    } catch (e) {
      print('Version check error: $e');
      // If version check fails, assume update is required for safety
      setState(() {
        _updateRequired = true;
        _updateCheckComplete = true;
        _updateInfo = {
          'title': 'Update Check Failed',
          'message': 'Unable to verify app version. Please update to continue.',
          'force_update': true,
        };
      });
    }
  }

  // Handle Android back button
  Future<bool> _onWillPop() async {
    if (!_isWindows && !_updateRequired) {
      final canGoBack = await (webViewService.controller as mobile_webview.WebViewController).canGoBack();
      if (canGoBack) {
        await webViewService.goBack();
        return false; // Don't exit app
      }
    }
    return true;
  }

  Future<void> _initWebView() async {
    try {
      await webViewService.initialize();
      _isWindows = webViewService.isWindows;

      // Mobile WebView settings
      if (!_isWindows) {
        final mobileController = webViewService.controller as mobile_webview.WebViewController;
        await mobileController.setJavaScriptMode(mobile_webview.JavaScriptMode.unrestricted);

        await mobileController.setNavigationDelegate(
          mobile_webview.NavigationDelegate(
            onPageStarted: (url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (url) async {
              setState(() {
                _isLoading = false;
                urlController.text = url;
              });

              // Enable "Remember Me" automatically
              await webViewService.enableRememberMePopup();

              // Save login status if user reached dashboard
              if (url.contains('/dashboard')) {
                await WebViewService.saveRememberLogin(true);
              }
            },
            onWebResourceError: (error) {
              setState(() => _isLoading = false);
              print('WebView Error: ${error.description}');
            },
            onProgress: (progress) {
              print('Loading progress: $progress%');
            },
          ),
        );
      } else {
        // Windows listeners
        (webViewService.controller as windows_webview.WebviewController)
            .loadingState.listen((state) {
          setState(() => _isLoading = state == windows_webview.LoadingState.loading);
        });

        (webViewService.controller as windows_webview.WebviewController)
            .url.listen((url) async {
          if (url != null) {
            setState(() => urlController.text = url);

            // Enable "Remember Me" automatically
            await webViewService.enableRememberMePopup();

            // Save login status if user reached dashboard
            if (url.contains('/dashboard')) {
              await WebViewService.saveRememberLogin(true);
            }
          }
        });
      }

      // Set a consistent user agent
      await webViewService.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0'
      );

      // Check if user previously remembered login
      bool remembered = await WebViewService.getRememberLogin();
      if (remembered) {
        // Directly go to dashboard if remembered
        await _loadUrlWithTimeout('https://experience.4excelerate.org/dashboard');
      } else {
        // Load initial login page
        await _loadUrlWithTimeout('https://experience.4excelerate.org/auth/login?returnUrl=%2Fdashboard');
      }
    } catch (e) {
      print('WebView initialization error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUrlWithTimeout(String url) async {
    try {
      await webViewService.loadUrl(url).timeout(const Duration(seconds: 30));
    } catch (e) {
      print('Timeout loading URL: $e');
      await webViewService.loadUrl('https://experience.4excelerate.org');
    }
  }

  void _loadUrl() {
    final url = urlController.text.trim();
    if (url.isNotEmpty) {
      webViewService.loadUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking for updates
    if (!_updateCheckComplete) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(29, 30, 37, 1),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Checking for updates...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Show update required screen if update is needed
    if (_updateRequired) {
      return UpdateRequiredScreen(updateInfo: _updateInfo);
    }

    // Otherwise show normal WebView
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          color: const Color.fromRGBO(29, 30, 37, 1),
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: Stack(
              children: [
                _buildWebView(),
                if (_isLoading) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    if (!_isWindows) {
      return mobile_webview.WebViewWidget(
        controller: webViewService.controller as mobile_webview.WebViewController,
      );
    } else {
      return ValueListenableBuilder<windows_webview.WebviewValue>(
        valueListenable: webViewService.controller as windows_webview.WebviewController,
        builder: (context, value, child) {
          if (!value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return windows_webview.Webview(
            webViewService.controller as windows_webview.WebviewController,
          );
        },
      );
    }
  }
}